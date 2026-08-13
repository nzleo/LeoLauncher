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
    var onboardingDone: Bool {
        get { UserDefaults.standard.bool(forKey: "onboardingDone") }
        set { UserDefaults.standard.set(newValue, forKey: "onboardingDone") }
    }

    @ObservationIgnored
    private var persistTask: Task<Void, Never>?
    @ObservationIgnored
    private var remoteTask: Task<Void, Never>?

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
                (opened[lhs.bundleID] ?? .distantPast) > (opened[rhs.bundleID] ?? .distantPast)
            }
            .prefix(8)
            .map { $0 }
    }

    var filtered: [AppRecord] {
        SearchEngine.ranked(apps: visibleApps, query: query)
    }

    var grouped: [(AppCategory, [AppRecord])] {
        let order = resolvedCategoryOrder()
        var buckets: [AppCategory: [AppRecord]] = [:]
        for app in visibleApps {
            buckets[app.category, default: []].append(app)
        }
        for key in buckets.keys {
            buckets[key]?.sort { lhs, rhs in
                let lCount = state.launchCounts[lhs.bundleID] ?? 0
                let rCount = state.launchCounts[rhs.bundleID] ?? 0
                if lCount != rCount { return lCount > rCount }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
        return order.compactMap { category in
            guard let items = buckets[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    func boot() async {
        iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        state = await CloudStore.shared.load()
        lastSyncedAt = state.updatedAt
        applyAppearance()
        refreshApps()
        IconCache.shared.prefetch(urls: visibleApps.map(\.url), pointSize: iconSize)
        Task { await self.enrichUnknownApps() }
        applyDockPolicy()
        applyLoginItem()
    }

    func refreshApps() {
        let overrides = state.overrides
        let raw = AppScanner.scan()
        apps = raw.map { item in
            let classified = Classifier.classify(
                bundleID: item.bundleID,
                name: item.name,
                systemCategory: item.systemCategory,
                override: overrides[item.bundleID]
            )
            return AppRecord(
                bundleID: item.bundleID,
                name: item.name,
                url: item.url,
                category: classified.0,
                aliases: Catalog.aliases(for: item.bundleID, name: item.name),
                isObscure: Catalog.obscureSystem.contains(item.bundleID),
                source: classified.1
            )
        }
        if selectedID == nil {
            selectedID = (query.isEmpty ? recents.first?.id : filtered.first?.id) ?? visibleApps.first?.id
        }
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

    func launch(_ app: AppRecord) {
        state.launchCounts[app.bundleID, default: 0] += 1
        state.lastOpened[app.bundleID] = Date()
        persistSoon()
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: app.url, configuration: configuration) { _, _ in }
        hide()
    }

    func reveal(_ app: AppRecord) {
        NSWorkspace.shared.activateFileViewerSelecting([app.url])
        hide()
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
        applyDockPolicy()
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
        let unknown = apps.filter { $0.source == .fallback || $0.source == .heuristic }
        guard !unknown.isEmpty else { return }
        await MainActor.run { isClassifying = true }
        defer { Task { @MainActor in isClassifying = false } }

        for app in unknown {
            if state.overrides[app.bundleID] != nil { continue }
            if Catalog.byBundle[app.bundleID] != nil { continue }
            if let genre = await ITunesLookup.genre(for: app.name),
               let category = Classifier.mapITunesGenre(genre) {
                await MainActor.run {
                    self.state.overrides[app.bundleID] = CategoryOverride(category: category, updatedAt: Date())
                    self.refreshApps()
                }
                continue
            }
            if let category = await LanguageClassifier.classify(name: app.name, bundleID: app.bundleID) {
                await MainActor.run {
                    self.state.overrides[app.bundleID] = CategoryOverride(category: category, updatedAt: Date())
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

    private func applyAppearance() {
        switch state.appearance {
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        default: NSApp.appearance = nil
        }
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
