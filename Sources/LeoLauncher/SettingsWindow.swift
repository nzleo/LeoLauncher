import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func show() {
        if window == nil {
            window = makeWindow()
        }
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        place(window)
        syncAppearance()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func makeKeyForCapture() {
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func syncAppearance() {
        guard let window else { return }
        switch LauncherStore.shared.state.appearance {
        case "dark":
            window.appearance = NSAppearance(named: .darkAqua)
        case "light":
            window.appearance = NSAppearance(named: .aqua)
        default:
            window.appearance = nil
        }
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: SettingsView(store: .shared))
        let window = NSWindow(contentViewController: hosting)
        window.title = "设置"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 620, height: 620))
        window.contentMinSize = NSSize(width: 560, height: 520)
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("LeoLauncherSettings")
        window.level = NSWindow.Level(rawValue: OverlayPanel.overlayLevel.rawValue + 1)
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        return window
    }

    private func place(_ window: NSWindow) {
        let point = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else {
            window.center()
            return
        }
        let size = window.frame.size
        window.setFrameOrigin(NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2
        ))
    }
}
