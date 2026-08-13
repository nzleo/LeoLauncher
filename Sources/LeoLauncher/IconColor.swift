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

enum TimeLane: String, CaseIterable, Identifiable, Sendable {
    case justNow
    case thisWeek
    case installed
    case thisMonth
    case earlier

    var id: String { rawValue }

    var title: String {
        switch self {
        case .justNow: "刚刚"
        case .thisWeek: "本周"
        case .installed: "新安装"
        case .thisMonth: "本月"
        case .earlier: "更早"
        }
    }

    var subtitle: String {
        switch self {
        case .justNow: "24 小时内打开过"
        case .thisWeek: "这周还用过"
        case .installed: "最近装上的"
        case .thisMonth: "这个月打开过"
        case .earlier: "按安装时间排列"
        }
    }

    var tint: Color {
        switch self {
        case .justNow: Ink.copper
        case .thisWeek: Color(red: 0.96, green: 0.72, blue: 0.32)
        case .installed: Color(red: 0.30, green: 0.78, blue: 0.62)
        case .thisMonth: Color(red: 0.45, green: 0.62, blue: 0.96)
        case .earlier: Color.white.opacity(0.45)
        }
    }

    var iconScale: CGFloat {
        switch self {
        case .justNow: 1.18
        case .thisWeek: 1.0
        case .installed: 1.0
        case .thisMonth: 0.94
        case .earlier: 0.86
        }
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
            }
        }

        return scores.max(by: { $0.value < $1.value })?.key ?? .gray
    }

    private static func classify(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> LogoHue {
        if brightness < 0.12 { return .gray }
        if saturation < 0.16 { return .gray }
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
