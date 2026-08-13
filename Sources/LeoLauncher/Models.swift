import AppKit
import Foundation
import SwiftUI

enum AppCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case ai
    case dev
    case office
    case chat
    case media
    case system
    case browser
    case notes
    case photo
    case learn
    case design
    case life
    case tasks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ai: "AI 工具"
        case .dev: "开发"
        case .office: "办公"
        case .chat: "沟通"
        case .media: "影音"
        case .system: "系统"
        case .browser: "浏览器"
        case .notes: "笔记"
        case .photo: "图像"
        case .learn: "学习"
        case .design: "设计"
        case .life: "生活"
        case .tasks: "任务"
        }
    }

    var symbol: String {
        switch self {
        case .ai: "sparkles"
        case .dev: "chevron.left.forwardslash.chevron.right"
        case .office: "doc.text"
        case .chat: "bubble.left.and.bubble.right"
        case .media: "play.rectangle"
        case .system: "gearshape"
        case .browser: "globe"
        case .notes: "note.text"
        case .photo: "photo"
        case .learn: "book"
        case .design: "paintbrush.pointed"
        case .life: "leaf"
        case .tasks: "checklist"
        }
    }

    var tint: Color {
        switch self {
        case .ai: Color(red: 0.66, green: 0.55, blue: 0.98)
        case .dev: Color(red: 0.22, green: 0.74, blue: 0.97)
        case .office: Color(red: 0.20, green: 0.83, blue: 0.60)
        case .chat: Color(red: 0.38, green: 0.65, blue: 0.98)
        case .media: Color(red: 0.98, green: 0.57, blue: 0.24)
        case .system: Color(red: 0.58, green: 0.64, blue: 0.72)
        case .browser: Color(red: 0.13, green: 0.83, blue: 0.93)
        case .notes: Color(red: 0.98, green: 0.75, blue: 0.14)
        case .photo: Color(red: 0.96, green: 0.45, blue: 0.71)
        case .learn: Color(red: 0.29, green: 0.87, blue: 0.50)
        case .design: Color(red: 0.96, green: 0.25, blue: 0.37)
        case .life: Color(red: 0.18, green: 0.83, blue: 0.75)
        case .tasks: Color(red: 0.64, green: 0.90, blue: 0.21)
        }
    }

    static let colorOrder: [AppCategory] = [
        .design, .photo, .media, .notes, .tasks, .learn, .office,
        .life, .browser, .dev, .chat, .ai, .system
    ]

    var colorRank: Int {
        Self.colorOrder.firstIndex(of: self) ?? 99
    }

    static let boardOrder: [AppCategory] = [
        .ai, .dev, .office, .chat, .media, .system,
        .tasks, .browser, .notes, .photo, .learn, .design, .life
    ]
}

struct AppRecord: Identifiable, Hashable, Sendable {
    var id: String { bundleID }
    var bundleID: String
    var name: String
    var url: URL
    var category: AppCategory
    var aliases: [String]
    var isObscure: Bool
    var source: ClassificationSource
    var installedAt: Date
}

enum ClassificationSource: String, Codable, Sendable {
    case user
    case catalog
    case heuristic
    case itunes
    case model
    case fallback
}

struct CategoryOverride: Codable, Hashable, Sendable {
    var category: AppCategory
    var updatedAt: Date
}

struct PersistedState: Codable, Equatable, Sendable {
    var version: Int
    var updatedAt: Date
    var overrides: [String: CategoryOverride]
    var hiddenBundleIDs: [String]
    var showObscureSystemApps: Bool
    var hideAppNames: Bool
    var iconSize: Double
    var categoryOrder: [String]
    var launchCounts: [String: Int]
    var lastOpened: [String: Date]
    var appearance: String
    var launchAtLogin: Bool
    var showInDock: Bool
    var sortMode: String?
    var overlayStyle: String?
    var wallpaperFileName: String?
    var wallpaperOpacity: Double?
    var quoteMode: String?
    var quotePlacement: String?
    var customGreeting: String?

    static let `default` = PersistedState(
        version: 2,
        updatedAt: Date(),
        overrides: [:],
        hiddenBundleIDs: [],
        showObscureSystemApps: false,
        hideAppNames: true,
        iconSize: 56,
        categoryOrder: AppCategory.boardOrder.map(\.rawValue),
        launchCounts: [:],
        lastOpened: [:],
        appearance: "dark",
        launchAtLogin: false,
        showInDock: true,
        sortMode: SortMode.function.rawValue,
        overlayStyle: OverlayStyle.frosted.rawValue,
        wallpaperFileName: nil,
        wallpaperOpacity: 0.55,
        quoteMode: QuoteMode.both.rawValue,
        quotePlacement: QuotePlacement.bottom.rawValue,
        customGreeting: nil
    )
}
