import Foundation

enum Classifier {
    static func classify(
        bundleID: String,
        name: String,
        systemCategory: String?,
        override: CategoryOverride?
    ) -> (AppCategory, ClassificationSource) {
        if let override {
            return (override.category, .user)
        }

        if let category = Catalog.byBundle[bundleID] {
            return (category, .catalog)
        }

        let normalized = normalize(name)
        if let category = Catalog.byName[normalized] {
            return (category, .catalog)
        }

        if let category = heuristic(name: normalized, systemCategory: systemCategory, bundleID: bundleID) {
            return (category, .heuristic)
        }

        return (.system, .fallback)
    }

    static func heuristic(name: String, systemCategory: String?, bundleID: String) -> AppCategory? {
        let haystack = "\(name) \(bundleID)".lowercased()

        let rules: [(AppCategory, [String])] = [
            (.browser, ["browser", "chrome", "firefox", "edge", "arc", "brave", "浏览器"]),
            (.ai, ["chatgpt", "claude", "gemini", "copilot", "ollama", "qianwen", "doubao", "kimi", "perplexity", "openai", "anthropic"]),
            (.chat, ["wechat", "weixin", "telegram", "whatsapp", "slack", "discord", "qq", "lark", "feishu", "dingtalk", "meeting", "zoom", "teams"]),
            (.dev, ["code", "xcode", "terminal", "iterm", "docker", "git", "ide", "devtools", "developer"]),
            (.notes, ["notion", "obsidian", "bear", "notes", "markdown", "logseq"]),
            (.design, ["figma", "sketch", "photoshop", "illustrator", "design", "canva"]),
            (.media, ["music", "spotify", "vlc", "iina", "youtube", "bilibili", "douyin", "netflix"]),
            (.photo, ["photo", "lightroom", "capture"]),
            (.office, ["office", "word", "excel", "powerpoint", "pages", "numbers", "keynote", "wps"])
        ]

        for (category, keys) in rules where keys.contains(where: { haystack.contains($0) }) {
            return category
        }

        return mapSystemCategory(systemCategory)
    }

    static func mapSystemCategory(_ raw: String?) -> AppCategory? {
        guard let raw, !raw.isEmpty else { return nil }
        let value = raw.lowercased()
        if value.contains("developer") { return .dev }
        if value.contains("social") { return .chat }
        if value.contains("business") { return .chat }
        if value.contains("video") || value.contains("music") || value.contains("entertainment") || value.contains("news") || value.contains("game") {
            return .media
        }
        if value.contains("photo") { return .photo }
        if value.contains("graphics") || value.contains("design") { return .design }
        if value.contains("education") || value.contains("reference") || value.contains("book") { return .learn }
        if value.contains("travel") || value.contains("health") || value.contains("finance") { return .life }
        if value.contains("utilit") { return .system }
        return nil
    }

    static func mapITunesGenre(_ genre: String) -> AppCategory? {
        let value = genre.lowercased()
        if value.contains("developer") { return .dev }
        if value.contains("social") || value.contains("communication") { return .chat }
        if value.contains("photo") { return .photo }
        if value.contains("graphic") || value.contains("design") { return .design }
        if value.contains("music") || value.contains("entertainment") || value.contains("video") { return .media }
        if value.contains("reference") || value.contains("education") || value.contains("book") { return .learn }
        if value.contains("weather") || value.contains("health") || value.contains("lifestyle") || value.contains("finance") || value.contains("travel") {
            return .life
        }
        if value.contains("productivity") { return .office }
        if value.contains("business") { return .office }
        if value.contains("utilit") { return .system }
        if value.contains("browser") || value.contains("safari") { return .browser }
        return nil
    }

    static func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

struct ITunesLookup {
    struct Response: Decodable {
        var results: [Item]
        struct Item: Decodable {
            var primaryGenreName: String?
            var trackCensoredName: String?
        }
    }

    static func genre(for name: String) async -> String? {
        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: name),
            URLQueryItem(name: "entity", value: "macSoftware"),
            URLQueryItem(name: "country", value: "cn"),
            URLQueryItem(name: "limit", value: "1")
        ]
        guard let url = components?.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return decoded.results.first?.primaryGenreName
        } catch {
            return nil
        }
    }
}
