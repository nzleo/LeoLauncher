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
