import Foundation

actor CloudStore {
    static let shared = CloudStore()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    var iCloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func load() -> PersistedState {
        let urls = [cloudURL(), localURL()].compactMap { $0 }
        let states = urls.compactMap(read)
        if states.isEmpty { return .default }
        return states.reduce(PersistedState.default, merge)
    }

    func save(_ state: PersistedState) {
        var snapshot = state
        snapshot.updatedAt = Date()
        guard let data = try? encoder.encode(snapshot) else { return }
        write(data, to: localURL())
        if let cloud = cloudURL() {
            write(data, to: cloud)
        }
    }

    func merge(_ lhs: PersistedState, _ rhs: PersistedState) -> PersistedState {
        var merged = lhs.updatedAt >= rhs.updatedAt ? lhs : rhs
        var overrides = lhs.overrides
        for (key, value) in rhs.overrides {
            if let existing = overrides[key] {
                if value.updatedAt >= existing.updatedAt {
                    overrides[key] = value
                }
            } else {
                overrides[key] = value
            }
        }
        merged.overrides = overrides

        var counts = lhs.launchCounts
        for (key, value) in rhs.launchCounts {
            counts[key] = max(counts[key] ?? 0, value)
        }
        merged.launchCounts = counts

        var lastOpened = lhs.lastOpened
        for (key, value) in rhs.lastOpened {
            if let existing = lastOpened[key] {
                lastOpened[key] = max(existing, value)
            } else {
                lastOpened[key] = value
            }
        }
        merged.lastOpened = lastOpened
        merged.hiddenBundleIDs = Array(Set(lhs.hiddenBundleIDs).union(rhs.hiddenBundleIDs)).sorted()
        return merged
    }

    func localURL() -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LeoLauncher", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent("state.json")
    }

    func cloudURL() -> URL? {
        let cloudDocs = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/LeoLauncher", isDirectory: true)
        if FileManager.default.ubiquityIdentityToken == nil {
            return nil
        }
        try? FileManager.default.createDirectory(at: cloudDocs, withIntermediateDirectories: true)
        return cloudDocs.appendingPathComponent("state.json")
    }

    private func read(_ url: URL) -> PersistedState? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(PersistedState.self, from: data)
    }

    private func write(_ data: Data, to url: URL) {
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temp = directory.appendingPathComponent(".\(UUID().uuidString).tmp")
        do {
            try data.write(to: temp, options: .atomic)
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temp)
        } catch {
            try? data.write(to: url, options: .atomic)
            try? FileManager.default.removeItem(at: temp)
        }
    }
}
