import AppKit
import Foundation
import SwiftUI

enum LogoHue: String, CaseIterable, Identifiable, Sendable {
    case red
    case orange
    case yellow
    case green
    case teal
    case blue
    case purple
    case pink
    case gray

    var id: String { rawValue }

    var title: String {
        switch self {
        case .red: "红"
        case .orange: "橙"
        case .yellow: "黄"
        case .green: "绿"
        case .teal: "青"
        case .blue: "蓝"
        case .purple: "紫"
        case .pink: "粉"
        case .gray: "灰"
        }
    }

    var tint: Color {
        switch self {
        case .red: Color(red: 0.94, green: 0.28, blue: 0.32)
        case .orange: Color(red: 0.96, green: 0.55, blue: 0.18)
        case .yellow: Color(red: 0.96, green: 0.80, blue: 0.18)
        case .green: Color(red: 0.30, green: 0.78, blue: 0.42)
        case .teal: Color(red: 0.18, green: 0.78, blue: 0.76)
        case .blue: Color(red: 0.24, green: 0.56, blue: 0.98)
        case .purple: Color(red: 0.64, green: 0.42, blue: 0.96)
        case .pink: Color(red: 0.94, green: 0.42, blue: 0.70)
        case .gray: Color(red: 0.62, green: 0.64, blue: 0.68)
        }
    }
}

enum TimeLane: Hashable, Identifiable, Sendable {
    case week
    case month
    case quarter
    case halfYear
    case year(Int)
    case unknown

    var id: String {
        switch self {
        case .week: "week"
        case .month: "month"
        case .quarter: "quarter"
        case .halfYear: "halfYear"
        case .year(let year): "year-\(year)"
        case .unknown: "unknown"
        }
    }

    var title: String {
        switch self {
        case .week: "近 7 天"
        case .month: "近 1 个月"
        case .quarter: "近 3 个月"
        case .halfYear: "近半年"
        case .year(let year): "\(year) 年"
        case .unknown: "日期未知"
        }
    }

    var subtitle: String {
        switch self {
        case .week: "新安装"
        case .month: "30 天内装上的"
        case .quarter: "1 到 3 个月前"
        case .halfYear: "3 到 6 个月前"
        case .year: "这一年安装"
        case .unknown: "读不到安装日期"
        }
    }

    var tint: Color {
        switch self {
        case .week: Ink.copper
        case .month: Color(red: 0.96, green: 0.72, blue: 0.32)
        case .quarter: Color(red: 0.30, green: 0.78, blue: 0.62)
        case .halfYear: Color(red: 0.45, green: 0.62, blue: 0.96)
        case .year: Color.white.opacity(0.55)
        case .unknown: Color.white.opacity(0.35)
        }
    }
}

enum InstallDate {
    static func caption(_ date: Date) -> String {
        guard date > Date.distantPast.addingTimeInterval(86_400) else { return "未知" }
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
        if days <= 0 { return "今天" }
        if days == 1 { return "昨天" }
        if days < 7 { return "\(days) 天前" }
        return format(date, includeYear: days >= 180)
    }

    static func range(_ apps: [AppRecord]) -> String? {
        let dates = apps.map(\.installedAt).filter { $0 > Date.distantPast.addingTimeInterval(86_400) }
        guard let newest = dates.max(), let oldest = dates.min() else { return nil }
        if Calendar.current.isDate(newest, inSameDayAs: oldest) {
            return format(newest, includeYear: true)
        }
        return "\(format(oldest, includeYear: false)) – \(format(newest, includeYear: false))"
    }

    private static func format(_ date: Date, includeYear: Bool) -> String {
        if includeYear {
            return date.formatted(.dateTime.year().month().day().locale(Locale(identifier: "zh_CN")))
        }
        return date.formatted(.dateTime.month().day().locale(Locale(identifier: "zh_CN")))
    }
}

enum IconColorSampler {
    static func hue(in image: NSImage) -> LogoHue {
        guard let bitmap = raster(image) else { return .gray }
        var scores = Dictionary(uniqueKeysWithValues: LogoHue.allCases.map { ($0, 0.0) })
        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        guard width > 4, height > 4 else { return .gray }

        let insetX = max(1, width / 8)
        let insetY = max(1, height / 8)
        let step = max(1, min(width, height) / 24)
        var samples = 0.0
        var darkSamples = 0.0
        var chromaSamples = 0.0

        for y in stride(from: insetY, to: height - insetY, by: step) {
            for x in stride(from: insetX, to: width - insetX, by: step) {
                guard let raw = bitmap.colorAt(x: x, y: y),
                      let color = raw.usingColorSpace(.sRGB) else { continue }
                var hue: CGFloat = 0
                var saturation: CGFloat = 0
                var brightness: CGFloat = 0
                var alpha: CGFloat = 0
                color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                guard alpha > 0.38 else { continue }
                let bucket = classify(hue: hue, saturation: saturation, brightness: brightness)
                let weight = Double(max(saturation, 0.08) * brightness * alpha)
                scores[bucket, default: 0] += weight
                samples += 1
                if bucket == .gray {
                    if brightness < 0.45 { darkSamples += 1 }
                } else {
                    chromaSamples += 1
                }
            }
        }

        // A black icon with a speck of chroma must not lose to sat-weighted highlights.
        if samples > 0, darkSamples / samples > 0.55, chromaSamples / samples < 0.18 {
            return .gray
        }

        return scores.max(by: { $0.value < $1.value })?.key ?? .gray
    }

    private static func classify(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> LogoHue {
        // HSV saturation is chroma/value, so near-black cool grays look "highly saturated cyan".
        if brightness < 0.20 { return .gray }
        if saturation < 0.18 { return .gray }
        if saturation * brightness < 0.10 { return .gray }
        let degrees = hue * 360
        switch degrees {
        case 0..<18, 345...360: return .red
        case 18..<42: return .orange
        case 42..<70: return .yellow
        case 70..<155: return .green
        case 155..<190: return .teal
        case 190..<255: return .blue
        case 255..<292: return .purple
        default: return .pink
        }
    }

    private static func raster(_ image: NSImage) -> NSBitmapImageRep? {
        let pixels = 48
        let size = NSSize(width: pixels, height: pixels)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixels,
            pixelsHigh: pixels,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: pixels * 4,
            bitsPerPixel: 32
        ) else {
            return NSBitmapImageRep(data: image.tiffRepresentation ?? Data())
        }
        NSGraphicsContext.saveGraphicsState()
        if let context = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.current = context
            context.imageInterpolation = .medium
            image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)
        }
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }
}
