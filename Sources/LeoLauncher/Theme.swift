import AppKit
import SwiftUI

struct VisualBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blending
    }
}

enum OverlayStyle: String, CaseIterable, Identifiable, Sendable {
    case glass
    case frosted
    case transparent
    case ink

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glass: "玻璃"
        case .frosted: "毛玻璃"
        case .transparent: "透明"
        case .ink: "墨色"
        }
    }

    var subtitle: String {
        switch self {
        case .glass: "轻透，能看见桌面"
        case .frosted: "桌面模糊成底"
        case .transparent: "几乎不遮挡"
        case .ink: "夜间深色面板"
        }
    }

    var symbol: String {
        switch self {
        case .glass: "square.on.square"
        case .frosted: "cloud.fog"
        case .transparent: "circle.dotted"
        case .ink: "moon.fill"
        }
    }
}

struct OverlayPalette {
    var text: Color
    var mute: Color
    var line: Color
    var panelFill: Color
    var panelStroke: Color
    var chromeIdle: Color
    var usesMaterial: Bool
    var veilTop: Double
    var veilBottom: Double

    static let glass = OverlayPalette(
        text: Color.white,
        mute: Color.white.opacity(0.62),
        line: Color.white.opacity(0.18),
        panelFill: Color.white.opacity(0.10),
        panelStroke: Color.white.opacity(0.22),
        chromeIdle: Color.white.opacity(0.16),
        usesMaterial: true,
        veilTop: 0.22,
        veilBottom: 0.28
    )

    static let frosted = OverlayPalette(
        text: Color.white,
        mute: Color.white.opacity(0.58),
        line: Color.white.opacity(0.16),
        panelFill: Color.white.opacity(0.08),
        panelStroke: Color.white.opacity(0.18),
        chromeIdle: Color.white.opacity(0.14),
        usesMaterial: true,
        veilTop: 0.18,
        veilBottom: 0.26
    )

    static let transparent = OverlayPalette(
        text: Color.white,
        mute: Color.white.opacity(0.7),
        line: Color.white.opacity(0.2),
        panelFill: Color.black.opacity(0.18),
        panelStroke: Color.white.opacity(0.16),
        chromeIdle: Color.black.opacity(0.28),
        usesMaterial: false,
        veilTop: 0.28,
        veilBottom: 0.34
    )

    static let ink = OverlayPalette(
        text: Ink.ivory,
        mute: Ink.mute,
        line: Ink.line,
        panelFill: Ink.panel.opacity(0.82),
        panelStroke: Ink.line,
        chromeIdle: Ink.panel.opacity(0.9),
        usesMaterial: false,
        veilTop: 0,
        veilBottom: 0.45
    )

    static func make(_ style: OverlayStyle) -> OverlayPalette {
        switch style {
        case .glass: .glass
        case .frosted: .frosted
        case .transparent: .transparent
        case .ink: .ink
        }
    }
}

private struct OverlayPaletteKey: EnvironmentKey {
    static let defaultValue = OverlayPalette.ink
}

extension EnvironmentValues {
    var overlayPalette: OverlayPalette {
        get { self[OverlayPaletteKey.self] }
        set { self[OverlayPaletteKey.self] = newValue }
    }
}

struct OverlayBackdrop: View {
    var style: OverlayStyle
    var wallpaper: NSImage?
    var wallpaperOpacity: Double

    var body: some View {
        let palette = OverlayPalette.make(style)
        let blending: NSVisualEffectView.BlendingMode = wallpaper == nil ? .behindWindow : .withinWindow

        ZStack {
            if let wallpaper {
                GeometryReader { geo in
                    Image(nsImage: wallpaper)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .opacity(wallpaperOpacity)
                }
            }

            switch style {
            case .glass:
                VisualBlur(material: .hudWindow, blending: blending)
                Color.white.opacity(wallpaper == nil ? 0.05 : 0.08)
            case .frosted:
                VisualBlur(material: .fullScreenUI, blending: blending)
                Color.black.opacity(wallpaper == nil ? 0.12 : 0.16)
            case .transparent:
                Color.black.opacity(wallpaper == nil ? 0.16 : 0.10)
            case .ink:
                VisualBlur(material: .underWindowBackground, blending: blending)
                Ink.paper.opacity(wallpaper == nil ? 0.78 : 0.62)
                RadialGradient(
                    colors: [Ink.copper.opacity(0.22), .clear],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 640
                )
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(palette.veilTop),
                    .clear,
                    Color.black.opacity(palette.veilBottom)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

enum Ink {
    static let paper = Color(red: 0.07, green: 0.07, blue: 0.065)
    static let panel = Color(red: 0.12, green: 0.11, blue: 0.10)
    static let line = Color.white.opacity(0.10)
    static let copper = Color(red: 0.82, green: 0.58, blue: 0.34)
    static let ivory = Color(red: 0.93, green: 0.90, blue: 0.84)
    static let mute = Color.white.opacity(0.42)
}

enum LeoFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}
