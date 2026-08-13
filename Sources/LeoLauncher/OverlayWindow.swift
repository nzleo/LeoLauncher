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
            hosting.wantsLayer = true
            hosting.layer?.backgroundColor = NSColor.clear.cgColor
            panel.contentView = hosting
            panel.onEscape = { [weak self] in
                self?.handleEscape()
            }
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
        store?.rotateQuote()
        store?.requestSearchFocus()
        store?.screenInsets = ScreenChromeInsets.matching(screen)
        panel.setFrame(screen.frame, display: true)
        panel.contentView?.frame = NSRect(origin: .zero, size: screen.frame.size)
        panel.level = OverlayPanel.overlayLevel
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.store?.requestSearchFocus()
            self?.panel?.makeKey()
        }
    }

    func hide(animated: Bool = true) {
        guard let panel else { return }
        store?.hide()
        if animated, panel.isVisible {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.1
                panel.animator().alphaValue = 0
            }, completionHandler: {
                Task { @MainActor in
                    panel.orderOut(nil)
                    panel.alphaValue = 1
                }
            })
        } else {
            panel.orderOut(nil)
            panel.alphaValue = 1
        }
    }

    func handleEscape() {
        if let query = store?.query, !query.isEmpty {
            store?.query = ""
            store?.requestSearchFocus()
        } else {
            hide()
        }
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
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = OverlayPanel.overlayLevel
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = false
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
    }

    static var overlayLevel: NSWindow.Level {
        let dock = Int(CGWindowLevelForKey(.dockWindow))
        let popup = Int(CGWindowLevelForKey(.popUpMenuWindow))
        let overlay = Int(CGWindowLevelForKey(.overlayWindow))
        let status = Int(CGWindowLevelForKey(.statusWindow))
        return NSWindow.Level(rawValue: max(dock + 2, popup, overlay, status + 1))
    }

    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEscape?()
            return
        }
        super.keyDown(with: event)
    }
}

struct ScreenChromeInsets: Equatable, Sendable {
    var top: CGFloat
    var leading: CGFloat
    var bottom: CGFloat
    var trailing: CGFloat

    static let zero = ScreenChromeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    static func matching(_ screen: NSScreen) -> ScreenChromeInsets {
        let frame = screen.frame
        let visible = screen.visibleFrame
        return ScreenChromeInsets(
            top: max(0, frame.maxY - visible.maxY),
            leading: max(0, visible.minX - frame.minX),
            bottom: max(0, visible.minY - frame.minY),
            trailing: max(0, frame.maxX - visible.maxX)
        )
    }
}

struct OverlayRootView: View {
    @Bindable var store: LauncherStore
    var onDismiss: () -> Void

    var body: some View {
        OverlayView(store: store, onDismiss: onDismiss)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
