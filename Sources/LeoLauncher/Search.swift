import Foundation

struct SearchIndex: Sendable {
    struct Entry: Sendable {
        var bundleID: String
        var haystack: String
        var name: String
    }

    private var entries: [Entry] = []
    private var byID: [String: Entry] = [:]

    mutating func rebuild(_ apps: [AppRecord]) {
        entries = apps.map { app in
            var tokens: [String] = [app.name, app.category.title, app.bundleID]
            tokens.append(contentsOf: app.aliases)
            let latinName = Self.latin(app.name)
            tokens.append(latinName)
            tokens.append(initials(latinName))
            tokens.append(Self.latin(app.category.title))
            for alias in app.aliases {
                tokens.append(Self.latin(alias))
            }
            return Entry(
                bundleID: app.bundleID,
                haystack: tokens.joined(separator: " ").lowercased(),
                name: app.name
            )
        }
        byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.bundleID, $0) })
    }

    func ranked(query: String, apps: [AppRecord]) -> [AppRecord] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return apps }
        let latinNeedle = Self.latin(needle)

        return apps.compactMap { app -> (AppRecord, Int)? in
            guard let entry = byID[app.bundleID] else { return nil }
            guard let score = score(needle, latinNeedle: latinNeedle, entry: entry) else { return nil }
            return (app, score)
        }
        .sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0.name.localizedStandardCompare(rhs.0.name) == .orderedAscending
        }
        .map(\.0)
    }

    private func score(_ needle: String, latinNeedle: String, entry: Entry) -> Int? {
        let name = entry.name.lowercased()
        let haystack = entry.haystack
        if name == needle || name == latinNeedle { return 12_000 }
        if name.hasPrefix(needle) || name.hasPrefix(latinNeedle) { return 9_000 - name.count }
        if haystack.split(separator: " ").contains(where: { $0.hasPrefix(needle) || $0.hasPrefix(latinNeedle) }) {
            return 7_200
        }
        if haystack.contains(needle) || (!latinNeedle.isEmpty && haystack.contains(latinNeedle)) {
            return 4_800
        }
        if subsequence(needle, in: haystack) { return 1_400 }
        return nil
    }

    private func subsequence(_ query: String, in text: String) -> Bool {
        var iterator = text.makeIterator()
        for character in query {
            var found = false
            while let next = iterator.next() {
                if next == character {
                    found = true
                    break
                }
            }
            if !found { return false }
        }
        return true
    }

    static func latin(_ string: String) -> String {
        let mutable = NSMutableString(string: string)
        CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false)
        return (mutable as String)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }

    private func initials(_ latin: String) -> String {
        latin.split { !$0.isLetter }.compactMap { $0.first }.map(String.init).joined()
    }
}

enum SortMode: String, CaseIterable, Identifiable, Sendable {
    case function
    case color
    case time

    var id: String { rawValue }

    var title: String {
        switch self {
        case .function: "分类"
        case .color: "颜色"
        case .time: "时间"
        }
    }

    var symbol: String {
        switch self {
        case .function: "square.grid.2x2"
        case .color: "paintpalette"
        case .time: "clock"
        }
    }

    var help: String {
        switch self {
        case .function: "按功能分类"
        case .color: "按图标主色排列"
        case .time: "按安装时间排列"
        }
    }

    static func resolved(_ raw: String?) -> SortMode {
        switch raw {
        case "color": .color
        case "time", "usage": .time
        default: .function
        }
    }
}
