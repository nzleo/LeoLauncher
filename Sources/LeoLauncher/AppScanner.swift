import AppKit
import Foundation

enum AppScanner {
    static func scan() -> [RawApp] {
        let roots = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        var seen = Set<String>()
        var result: [RawApp] = []

        for root in roots {
            guard let items = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isApplicationKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in items where url.pathExtension == "app" {
                guard let raw = inspect(url) else { continue }
                if Catalog.skipBundlePrefixes.contains(where: { raw.bundleID.hasPrefix($0) }) {
                    continue
                }
                let key = raw.bundleID.isEmpty ? raw.url.path : raw.bundleID
                if seen.contains(key) { continue }
                seen.insert(key)
                result.append(raw)
            }
        }

        return result.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func inspect(_ url: URL) -> RawApp? {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
        guard values?.isDirectory == true else { return nil }

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

        return RawApp(
            bundleID: bundleID.isEmpty ? "path.\(url.path.hashValue)" : bundleID,
            name: trimmed,
            url: url,
            systemCategory: plist?["LSApplicationCategoryType"] as? String
        )
    }

    struct RawApp: Sendable {
        var bundleID: String
        var name: String
        var url: URL
        var systemCategory: String?
    }
}
