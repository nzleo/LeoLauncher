import AppKit
import Foundation

enum AppScanner {
    static var scanRoots: [URL] {
        [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
    }

    static var watchedRoots: [URL] {
        [
            URL(fileURLWithPath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
            URL(fileURLWithPath: "/System/Applications")
        ]
    }

    static func scan() -> [RawApp] {
        var seen = Set<String>()
        var result: [RawApp] = []

        for root in scanRoots {
            collectApps(in: root, depth: 0, maxDepth: 1, seen: &seen, into: &result)
        }

        let selfURL = Bundle.main.bundleURL.resolvingSymlinksInPath()
        if selfURL.pathExtension == "app", let raw = inspect(selfURL) {
            let key = raw.bundleID.isEmpty ? raw.url.path : raw.bundleID
            if !seen.contains(key) {
                result.append(raw)
            }
        }

        return result.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func collectApps(
        in directory: URL,
        depth: Int,
        maxDepth: Int,
        seen: inout Set<String>,
        into result: inout [RawApp]
    ) {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [
                .isApplicationKey,
                .isDirectoryKey,
                .isPackageKey,
                .addedToDirectoryDateKey,
                .creationDateKey,
                .contentModificationDateKey
            ],
            options: [.skipsHiddenFiles]
        ) else { return }

        for url in items {
            if url.pathExtension == "app" {
                let resolved = url.resolvingSymlinksInPath()
                guard let raw = inspect(resolved) else { continue }
                if Catalog.skipBundlePrefixes.contains(where: { raw.bundleID.hasPrefix($0) }) {
                    continue
                }
                let key = raw.bundleID.isEmpty ? raw.url.path : raw.bundleID
                if seen.contains(key) { continue }
                seen.insert(key)
                result.append(raw)
                continue
            }

            guard depth < maxDepth else { continue }
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
            if values?.isDirectory == true, values?.isPackage != true {
                collectApps(in: url, depth: depth + 1, maxDepth: maxDepth, seen: &seen, into: &result)
            }
        }
    }

    static func inspect(_ url: URL) -> RawApp? {
        let infoPlist = url.appendingPathComponent("Contents/Info.plist")
        guard FileManager.default.fileExists(atPath: infoPlist.path) else { return nil }

        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
        guard values?.isDirectory == true || values?.isPackage == true || url.pathExtension == "app" else { return nil }

        let bundle = Bundle(url: url)
        let plist = bundle?.infoDictionary
        let bundleID = bundle?.bundleIdentifier
            ?? (plist?["CFBundleIdentifier"] as? String)
            ?? ""
        let name = (plist?["CFBundleDisplayName"] as? String)
            ?? (plist?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.lowercased().contains("uninstaller") { return nil }

        let dates = try? url.resourceValues(forKeys: [
            .addedToDirectoryDateKey,
            .creationDateKey,
            .contentModificationDateKey
        ])
        let installedAt = dates?.addedToDirectoryDate
            ?? dates?.creationDate
            ?? dates?.contentModificationDate
            ?? Date.distantPast

        return RawApp(
            bundleID: bundleID.isEmpty ? "path.\(url.path.hashValue)" : bundleID,
            name: trimmed,
            url: url,
            systemCategory: plist?["LSApplicationCategoryType"] as? String,
            installedAt: installedAt
        )
    }

    struct RawApp: Sendable {
        var bundleID: String
        var name: String
        var url: URL
        var systemCategory: String?
        var installedAt: Date
    }
}
