import AppKit
import QuartzCore
import SwiftUI

@MainActor
final class OverlayController {
    private var panel: OverlayPanel?
    private var store: LauncherStore?

    func bind(store: LauncherStore) {
        self.store = store
        if panel == nil {
            let panel = OverlayPanel()
            let root = OverlayRootView(store: store) { [weak self] in
                self?.hide()
            }
            let hosting = NSHostingView(rootView: root)
            hosting.autoresizingMask = [.width, .height]
            panel.contentView = hosting
            self.panel = panel
        }
    }

    func toggle(focusSearch: Bool = false) {
        guard let panel else { return }
        if panel.isVisible {
            hide()
        } else {
            show(focusSearch: focusSearch)
        }
    }

    func show(focusSearch: Bool = false) {
        guard let panel, let screen = screenForMouse() else { return }
        store?.isVisible = true
        panel.setFrame(screen.frame, display: true)
        panel.contentView?.frame = NSRect(origin: .zero, size: screen.frame.size)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard let panel else { return }
        store?.hide()
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            panel.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor in
                panel.orderOut(nil)
                panel.alphaValue = 1
            }
        })
    }

    private func screenForMouse() -> NSScreen? {
        let point = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
    }
}

final class OverlayPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = false
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

struct OverlayRootView: View {
    @Bindable var store: LauncherStore
    var onDismiss: () -> Void

    var body: some View {
        OverlayView(store: store, onDismiss: onDismiss)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
