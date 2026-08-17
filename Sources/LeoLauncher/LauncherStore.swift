import AppKit
import Foundation
import Observation
import ServiceManagement

@Observable
@MainActor
final class LauncherStore {
    static let shared = LauncherStore()

    var apps: [AppRecord] = []
    var query = ""
    var selectedID: String?
    var isVisible = false
    var state = PersistedState.default
    var iCloudAvailable = false
    var lastSyncedAt: Date?
    var isClassifying = false
    var searchIndex = SearchIndex()
    var focusTick = 0
    var wallpaperImage: NSImage?
    var screenInsets = ScreenChromeInsets.zero
    var quoteIndex = 0

    var logoHues: [String: LogoHue] = [:]

    var sortMode: SortMode {
        SortMode.resolved(state.sortMode)
    }
    var overlayStyle: OverlayStyle {
        OverlayStyle(rawValue: state.overlayStyle ?? OverlayStyle.frosted.rawValue) ?? .frosted
    }
    var wallpaperOpacity: Double {
        min(max(state.wallpaperOpacity ?? 0.55, 0.15), 1)
    }
    var quoteMode: QuoteMode {
        QuoteMode(rawValue: state.quoteMode ?? QuoteMode.both.rawValue) ?? .both
    }
    var quotePlacement: QuotePlacement {
        QuotePlacement(rawValue: state.quotePlacement ?? QuotePlacement.bottom.rawValue) ?? .bottom
    }
    var greeting: String {
        let custom = state.customGreeting?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return custom.isEmpty ? SystemIdentity.defaultGreeting : custom
    }
    var usesCustomGreeting: Bool {
        !(state.customGreeting?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty
    }
    var mainHotKey: HotKeyCombo {
        state.mainHotKey ?? .defaultMain
    }
    var searchHotKey: HotKeyCombo {
        state.searchHotKey ?? .defaultSearch
    }
    var usesCustomHotKeys: Bool {
        state.mainHotKey != nil || state.searchHotKey != nil
    }
    var currentQuote: FamousQuote {
        let quotes = QuoteBook.all
        guard !quotes.isEmpty else {
            return FamousQuote(id: 0, english: "", chinese: "", author: "")
        }
        return quotes[quoteIndex % quotes.count]
    }
    var onboardingDone: Bool {
        get { UserDefaults.standard.bool(forKey: "onboardingDone") }
        set { UserDefaults.standard.set(newValue, forKey: "onboardingDone") }
    }

    @ObservationIgnored
    var onDismissOverlay: (() -> Void)?
    @ObservationIgnored
    private var suppressReopenUntil: Date?
    @ObservationIgnored
    private var persistTask: Task<Void, Never>?
    @ObservationIgnored
    private var remoteTask: Task<Void, Never>?
    @ObservationIgnored
    private var folderWatcher: AppFolderWatcher?

    var shouldSuppressReopen: Bool {
        guard let until = suppressReopenUntil else { return false }
        return Date() < until
    }

    var iconSize: CGFloat { CGFloat(state.iconSize) }
    var hideAppNames: Bool { state.hideAppNames }

    var visibleApps: [AppRecord] {
        let hidden = Set(state.hiddenBundleIDs)
        return apps.filter { app in
            if hidden.contains(app.bundleID) { return false }
            if app.isObscure && !state.showObscureSystemApps { return false }
            return true
        }
    }

    var recents: [AppRecord] {
        let opened = state.lastOpened
        return visibleApps
            .filter { opened[$0.bundleID] != nil }
            .sorted { lhs, rhs in
                let lCount = state.launchCounts[lhs.bundleID] ?? 0
                let rCount = state.launchCounts[rhs.bundleID] ?? 0
                if lCount != rCount { return lCount > rCount }
                return (opened[lhs.bundleID] ?? .distantPast) > (opened[rhs.bundleID] ?? .distantPast)
            }
            .prefix(8)
            .map { $0 }
    }

    var filtered: [AppRecord] {
        searchIndex.ranked(query: query, apps: visibleApps)
    }

    var grouped: [(AppCategory, [AppRecord])] {
        var buckets: [AppCategory: [AppRecord]] = [:]
        for app in visibleApps {
            buckets[app.category, default: []].append(app)
        }
        for key in buckets.keys {
            buckets[key]?.sort(by: usageThenName)
        }
        let order = resolvedCategoryOrder()
        return order.compactMap { category in
            guard let items = buckets[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var colorGroups: [(LogoHue, [AppRecord])] {
        var buckets: [LogoHue: [AppRecord]] = [:]
        for app in visibleApps {
            buckets[logoHues[app.bundleID] ?? .gray, default: []].append(app)
        }
        for key in buckets.keys {
            buckets[key]?.sort(by: usageThenName)
        }
        return LogoHue.allCases.compactMap { hue in
            guard let items = buckets[hue], !items.isEmpty else { return nil }
            return (hue, items)
        }
    }

    var timeGroups: [(TimeLane, [AppRecord])] {
        var buckets: [TimeLane: [AppRecord]] = [:]
        for app in visibleApps {
            buckets[installLane(for: app), default: []].append(app)
        }
        for key in buckets.keys {
            buckets[key]?.sort { lhs, rhs in
                if lhs.installedAt != rhs.installedAt { return lhs.installedAt > rhs.installedAt }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
        let years = buckets.keys.compactMap { lane -> Int? in
            if case .year(let year) = lane { return year }
            return nil
        }.sorted(by: >)
        var order: [TimeLane] = [.week, .month, .quarter, .halfYear]
        order.append(contentsOf: years.map(TimeLane.year))
        order.append(.unknown)
        return order.compactMap { lane in
            guard let items = buckets[lane], !items.isEmpty else { return nil }
            return (lane, items)
        }
    }

    func boot() async {
        iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        state = await CloudStore.shared.load()
        var migrated = false
        if state.version < 2 {
            state.version = 2
            state.showInDock = true
            migrated = true
        }
        if state.version < 3 {
            state.version = 3
            state.hideAppNames = false
            migrated = true
        }
        if state.version < 4 {
            migrateFactoryHotKeysIfNeeded()
            if state.appearance == "dark" {
                state.appearance = "system"
            }
            state.version = 4
            migrated = true
        }
        lastSyncedAt = state.updatedAt
        applyAppearance()
        loadWallpaper()
        refreshApps()
        startWatchingAppFolders()
        IconCache.shared.prefetch(urls: visibleApps.map(\.url), pointSize: iconSize)
        Task { await self.enrichUnknownApps() }
        applyDockPolicy()
        applyLoginItem()
        applyHotKeys()
        if migrated {
            persistNow()
        }
    }

    private func startWatchingAppFolders() {
        let watcher = AppFolderWatcher {
            Task { @MainActor in
                LauncherStore.shared.refreshApps()
            }
        }
        watcher.start(paths: AppScanner.watchedRoots.map(\.path))
        folderWatcher = watcher
    }

    func refreshApps() {
        let overrides = state.overrides
        let raw = AppScanner.scan()
        apps = raw.map { item in
            let classified = Classifier.classify(
                bundleID: item.bundleID,
                name: item.name,
                systemCategory: item.systemCategory,
                override: overrides[item.bundleID],
                inferred: state.inferences?[item.bundleID]
            )
            return AppRecord(
                bundleID: item.bundleID,
                name: item.name,
                url: item.url,
                category: classified.0,
                aliases: Catalog.aliases(for: item.bundleID, name: item.name),
                isObscure: Catalog.obscureSystem.contains(item.bundleID),
                source: classified.1,
                installedAt: item.installedAt
            )
        }
        searchIndex.rebuild(apps)
        if selectedID == nil {
            selectedID = (query.isEmpty ? recents.first?.id : filtered.first?.id) ?? visibleApps.first?.id
        }
        sampleLogoHues()
    }

    func toggle() {
        isVisible.toggle()
        if isVisible {
            query = ""
            selectedID = recents.first?.id ?? visibleApps.first?.id
            refreshApps()
        }
    }

    func hide() {
        isVisible = false
        query = ""
    }

    func dismissOverlay() {
        suppressReopenUntil = Date().addingTimeInterval(1.2)
        hide()
        onDismissOverlay?()
    }

    func clearRecents() {
        state.lastOpened = [:]
        state.recentsClearedAt = Date()
        persistNow()
    }

    func launch(_ app: AppRecord) {
        state.launchCounts[app.bundleID, default: 0] += 1
        state.lastOpened[app.bundleID] = Date()
        persistSoon()
        dismissOverlay()
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: app.url, configuration: configuration) { _, _ in }
    }

    func reveal(_ app: AppRecord) {
        dismissOverlay()
        NSWorkspace.shared.activateFileViewerSelecting([app.url])
    }

    func reassign(_ app: AppRecord, to category: AppCategory) {
        state.overrides[app.bundleID] = CategoryOverride(category: category, updatedAt: Date())
        refreshApps()
        persistSoon()
    }

    func hideApp(_ app: AppRecord) {
        if !state.hiddenBundleIDs.contains(app.bundleID) {
            state.hiddenBundleIDs.append(app.bundleID)
        }
        refreshApps()
        persistSoon()
    }

    func unhide(_ bundleID: String) {
        state.hiddenBundleIDs.removeAll { $0 == bundleID }
        refreshApps()
        persistSoon()
    }

    func moveSelection(_ delta: Int) {
        let pool = query.isEmpty ? (recents + visibleApps) : filtered
        guard !pool.isEmpty else { return }
        let unique = uniqueByID(pool)
        let current = unique.firstIndex(where: { $0.id == selectedID }) ?? 0
        let next = (current + delta + unique.count) % unique.count
        selectedID = unique[next].id
    }

    func launchSelected() {
        let pool = query.isEmpty ? visibleApps : filtered
        if let match = pool.first(where: { $0.id == selectedID }) {
            launch(match)
        } else if let first = filtered.first {
            launch(first)
        }
    }

    func updateIconSize(_ value: Double) {
        state.iconSize = value
        persistSoon()
    }

    func updateHideNames(_ value: Bool) {
        state.hideAppNames = value
        persistSoon()
    }

    func updateShowObscure(_ value: Bool) {
        state.showObscureSystemApps = value
        refreshApps()
        persistSoon()
    }

    func updateAppearance(_ value: String) {
        state.appearance = value
        applyAppearance()
        persistSoon()
    }

    func updateShowInDock(_ value: Bool) {
        state.showInDock = value
        applyDockPolicy()
        persistSoon()
    }

    func updateLaunchAtLogin(_ value: Bool) {
        state.launchAtLogin = value
        applyLoginItem()
        persistSoon()
    }

    func updateSortMode(_ mode: SortMode) {
        state.sortMode = mode.rawValue
        persistSoon()
    }

    func updateOverlayStyle(_ style: OverlayStyle) {
        state.overlayStyle = style.rawValue
        persistSoon()
    }

    func updateWallpaperOpacity(_ value: Double) {
        state.wallpaperOpacity = min(max(value, 0.15), 1)
        persistSoon()
    }

    func updateQuoteMode(_ mode: QuoteMode) {
        state.quoteMode = mode.rawValue
        persistSoon()
    }

    func updateQuotePlacement(_ placement: QuotePlacement) {
        state.quotePlacement = placement.rawValue
        persistSoon()
    }

    func updateGreeting(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == SystemIdentity.defaultGreeting {
            state.customGreeting = nil
        } else {
            state.customGreeting = trimmed
        }
        persistSoon()
    }

    func resetGreeting() {
        state.customGreeting = nil
        persistSoon()
    }

    @discardableResult
    func updateMainHotKey(_ combo: HotKeyCombo) -> String? {
        if let error = combo.validationError { return error }
        if combo == searchHotKey {
            return "与搜索快捷键（\(searchHotKey.display)）冲突"
        }
        let previous = state.mainHotKey
        state.mainHotKey = combo
        if let error = applyHotKeys() {
            state.mainHotKey = previous
            _ = applyHotKeys()
            return error
        }
        persistSoon()
        return nil
    }

    @discardableResult
    func updateSearchHotKey(_ combo: HotKeyCombo) -> String? {
        if let error = combo.validationError { return error }
        if combo == mainHotKey {
            return "与主界面快捷键（\(mainHotKey.display)）冲突"
        }
        let previous = state.searchHotKey
        state.searchHotKey = combo
        if let error = applyHotKeys() {
            state.searchHotKey = previous
            _ = applyHotKeys()
            return error
        }
        persistSoon()
        return nil
    }

    func resetMainHotKey() {
        state.mainHotKey = nil
        _ = applyHotKeys()
        persistSoon()
    }

    func resetSearchHotKey() {
        state.searchHotKey = nil
        _ = applyHotKeys()
        persistSoon()
    }

    func resetHotKeys() {
        state.mainHotKey = nil
        state.searchHotKey = nil
        _ = applyHotKeys()
        persistSoon()
    }

    @discardableResult
    func applyHotKeys() -> String? {
        HotKeyCenter.shared.apply(
            main: mainHotKey,
            search: searchHotKey
        )
    }

    func rotateQuote() {
        let count = QuoteBook.all.count
        guard count > 1 else { return }
        var next = Int.random(in: 0..<count)
        if next == quoteIndex {
            next = (next + 1) % count
        }
        quoteIndex = next
    }

    func importWallpaper(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return }
        let ext = ["png", "jpg", "jpeg", "heic", "tif", "tiff", "webp"].contains(url.pathExtension.lowercased())
            ? url.pathExtension.lowercased()
            : "png"
        let name = "wallpaper.\(ext == "jpeg" ? "jpg" : ext)"
        removeWallpaperFiles()
        writeWallpaper(data, name: name)
        state.wallpaperFileName = name
        if overlayStyle == .ink {
            state.overlayStyle = OverlayStyle.frosted.rawValue
        }
        wallpaperImage = NSImage(data: data)
        persistSoon()
    }

    func clearWallpaper() {
        removeWallpaperFiles()
        state.wallpaperFileName = nil
        wallpaperImage = nil
        persistSoon()
    }

    func requestSearchFocus() {
        focusTick += 1
    }

    func persistNow() {
        persistTask?.cancel()
        let snapshot = state
        Task.detached {
            await CloudStore.shared.save(snapshot)
        }
        lastSyncedAt = Date()
        iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
    }

    func reloadFromCloud() async {
        let loaded = await CloudStore.shared.load()
        state = loaded
        lastSyncedAt = loaded.updatedAt
        refreshApps()
        applyAppearance()
        loadWallpaper()
        applyDockPolicy()
        applyHotKeys()
    }

    func reclassifyUnknown() {
        Task { await enrichUnknownApps() }
    }

    private func persistSoon() {
        persistTask?.cancel()
        persistTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            persistNow()
        }
    }

    private func enrichUnknownApps() async {
        let unknown = apps.filter { $0.source == .fallback || $0.category == .unsorted }
        guard !unknown.isEmpty else { return }
        await MainActor.run { isClassifying = true }
        defer { Task { @MainActor in isClassifying = false } }

        for app in unknown {
            if state.overrides[app.bundleID] != nil { continue }
            if Catalog.byBundle[app.bundleID] != nil { continue }
            if let genre = await ITunesLookup.genre(for: app.name),
               let category = Classifier.mapITunesGenre(genre),
               category != .unsorted {
                await MainActor.run {
                    var inferences = self.state.inferences ?? [:]
                    inferences[app.bundleID] = InferredCategory(category: category, source: .itunes, updatedAt: Date())
                    self.state.inferences = inferences
                    self.refreshApps()
                }
                continue
            }
            if let category = await LanguageClassifier.classify(name: app.name, bundleID: app.bundleID),
               category != .unsorted {
                await MainActor.run {
                    var inferences = self.state.inferences ?? [:]
                    inferences[app.bundleID] = InferredCategory(category: category, source: .model, updatedAt: Date())
                    self.state.inferences = inferences
                    self.refreshApps()
                }
            }
        }
        await MainActor.run { self.persistNow() }
    }

    private func resolvedCategoryOrder() -> [AppCategory] {
        let stored = state.categoryOrder.compactMap(AppCategory.init(rawValue:))
        let missing = AppCategory.boardOrder.filter { !stored.contains($0) }
        return stored + missing
    }

    private func uniqueByID(_ apps: [AppRecord]) -> [AppRecord] {
        var seen = Set<String>()
        return apps.filter { seen.insert($0.id).inserted }
    }

    private func usageThenName(_ lhs: AppRecord, _ rhs: AppRecord) -> Bool {
        let lCount = state.launchCounts[lhs.bundleID] ?? 0
        let rCount = state.launchCounts[rhs.bundleID] ?? 0
        if lCount != rCount { return lCount > rCount }
        let lOpen = state.lastOpened[lhs.bundleID] ?? .distantPast
        let rOpen = state.lastOpened[rhs.bundleID] ?? .distantPast
        if lOpen != rOpen { return lOpen > rOpen }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    private func installLane(for app: AppRecord) -> TimeLane {
        guard app.installedAt > Date.distantPast.addingTimeInterval(86_400) else { return .unknown }
        let days = Date().timeIntervalSince(app.installedAt) / 86_400
        if days < 7 { return .week }
        if days < 30 { return .month }
        if days < 90 { return .quarter }
        if days < 180 { return .halfYear }
        return .year(Calendar.current.component(.year, from: app.installedAt))
    }

    private func sampleLogoHues() {
        let jobs = visibleApps.compactMap { app -> (String, URL)? in
            logoHues[app.bundleID] == nil ? (app.bundleID, app.url) : nil
        }
        guard !jobs.isEmpty else { return }
        Task { @MainActor in
            for job in jobs {
                if Task.isCancelled { return }
                let image = IconCache.shared.image(for: job.1, pointSize: 64)
                logoHues[job.0] = IconColorSampler.hue(in: image)
                await Task.yield()
            }
        }
    }

    private func migrateFactoryHotKeysIfNeeded() {
        if let main = state.mainHotKey, main == .legacyDefaultMain {
            state.mainHotKey = nil
        }
        if let search = state.searchHotKey, search == .legacyDefaultSearch {
            state.searchHotKey = nil
        }
    }

    private func applyAppearance() {
        switch state.appearance {
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        default: NSApp.appearance = nil
        }
        SettingsWindowController.shared.syncAppearance()
    }

    private func loadWallpaper() {
        guard let name = state.wallpaperFileName else {
            wallpaperImage = nil
            return
        }
        for url in wallpaperURLs(name: name) {
            if FileManager.default.fileExists(atPath: url.path),
               let image = NSImage(contentsOf: url) {
                wallpaperImage = image
                return
            }
        }
        wallpaperImage = nil
    }

    private func writeWallpaper(_ data: Data, name: String) {
        for url in wallpaperURLs(name: name) {
            let directory = url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }

    private func removeWallpaperFiles() {
        let names = [
            state.wallpaperFileName,
            "wallpaper.png", "wallpaper.jpg", "wallpaper.heic", "wallpaper.tif", "wallpaper.tiff", "wallpaper.webp"
        ].compactMap { $0 }
        for name in Set(names) {
            for url in wallpaperURLs(name: name) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func wallpaperURLs(name: String) -> [URL] {
        var urls: [URL] = []
        let local = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LeoLauncher", isDirectory: true)
            .appendingPathComponent(name)
        urls.append(local)
        if FileManager.default.ubiquityIdentityToken != nil {
            let cloud = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/LeoLauncher/\(name)")
            urls.append(cloud)
        }
        return urls
    }

    private func applyDockPolicy() {
        NSApp.setActivationPolicy(state.showInDock ? .regular : .accessory)
    }

    private func applyLoginItem() {
        do {
            if state.launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Login item registration is best-effort when running outside /Applications.
        }
    }
}

enum LanguageClassifier {
    static func classify(name: String, bundleID: String) async -> AppCategory? {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return await FoundationClassify.run(name: name, bundleID: bundleID)
        }
        #endif
        return nil
    }
}

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26.0, *)
enum FoundationClassify {
    static func run(name: String, bundleID: String) async -> AppCategory? {
        let session = LanguageModelSession()
        let prompt = """
        将这个 macOS 应用分到且仅分到一个类别。只返回类别 id，不要解释。
        可选 id: ai, dev, office, chat, media, system, browser, notes, photo, learn, design, life, tasks
        应用名: \(name)
        Bundle ID: \(bundleID)
        """
        do {
            let response = try await session.respond(to: prompt)
            let raw = response.content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let token = raw.split(whereSeparator: { !$0.isLetter }).first.map(String.init) ?? raw
            return AppCategory(rawValue: token)
        } catch {
            return nil
        }
    }
}
#endif
