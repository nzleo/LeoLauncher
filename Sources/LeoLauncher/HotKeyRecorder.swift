import AppKit
import SwiftUI

enum HotKeySlot: String {
    case main
    case search
}

struct HotKeyRecorderButton: View {
    var combo: HotKeyCombo
    var isRecording: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isRecording ? "按下快捷键…" : combo.display)
                .font(.body.monospaced())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isRecording ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isRecording ? Color.accentColor : Color.secondary.opacity(0.35))
                }
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(isRecording ? "按下新的组合键，Esc 取消" : "点击后按下新的快捷键")
    }
}

struct HotKeyCaptureProbe: NSViewRepresentable {
    var isActive: Bool
    var onEvent: (NSEvent) -> Bool

    func makeNSView(context: Context) -> HotKeyCaptureView {
        let view = HotKeyCaptureView()
        view.isActive = isActive
        view.onEvent = onEvent
        return view
    }

    func updateNSView(_ nsView: HotKeyCaptureView, context: Context) {
        nsView.onEvent = onEvent
        nsView.isActive = isActive
    }
}

/// Captures modifier+key combos via a local NSEvent monitor (not a TextField).
final class HotKeyCaptureView: NSView {
    var onEvent: ((NSEvent) -> Bool)?
    var isActive = false {
        didSet {
            if isActive {
                window?.makeKey()
                window?.makeFirstResponder(self)
            }
        }
    }
    nonisolated(unsafe) private var monitor: Any?

    override var acceptsFirstResponder: Bool { isActive }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            stop()
        } else {
            start()
        }
    }

    override func keyDown(with event: NSEvent) {
        if isActive, onEvent?(event) == true {
            return
        }
        super.keyDown(with: event)
    }

    private func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isActive else { return event }
            let consumed = self.onEvent?(event) ?? false
            return consumed ? nil : event
        }
    }

    private func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
