import Foundation

enum SearchEngine {
    static func ranked(apps: [AppRecord], query: String) -> [AppRecord] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return apps }

        return apps.compactMap { app -> (AppRecord, Int)? in
            guard let score = score(needle, app: app) else { return nil }
            return (app, score)
        }
        .sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0.name.localizedStandardCompare(rhs.0.name) == .orderedAscending
        }
        .map(\.0)
    }

    static func score(_ query: String, app: AppRecord) -> Int? {
        let q = query.lowercased()
        var best: Int?

        func consider(_ text: String, weight: Int) {
            let t = text.lowercased()
            guard !t.isEmpty else { return }
            if t == q {
                best = max(best ?? 0, 10_000 + weight)
            } else if t.hasPrefix(q) {
                best = max(best ?? 0, 8_000 + weight - t.count)
            } else if t.contains(q) {
                best = max(best ?? 0, 5_000 + weight - t.count)
            } else if subsequence(q, in: t) {
                best = max(best ?? 0, 1_200 + weight)
            }
        }

        consider(app.name, weight: 400)
        consider(app.category.title, weight: 80)
        for alias in app.aliases {
            consider(alias, weight: 240)
        }
        consider(app.bundleID, weight: 40)
        return best
    }

    private static func subsequence(_ query: String, in text: String) -> Bool {
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
}
