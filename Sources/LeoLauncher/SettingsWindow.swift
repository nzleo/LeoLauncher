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
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: SettingsView(store: .shared))
        let window = NSWindow(contentViewController: hosting)
        window.title = "设置"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 620, height: 560))
        window.contentMinSize = NSSize(width: 560, height: 480)
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("LeoLauncherSettings")
        window.level = .floating
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
