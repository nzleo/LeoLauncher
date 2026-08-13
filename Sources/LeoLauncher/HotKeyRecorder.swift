import AppKit
import Carbon
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
        nsView.isActive = isActive
        nsView.onEvent = onEvent
    }
}

final class HotKeyCaptureView: NSView {
    var isActive = false
    var onEvent: ((NSEvent) -> Bool)?
    nonisolated(unsafe) private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            stop()
        } else {
            start()
        }
    }

    private func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isActive else { return event }
            guard self.window?.isKeyWindow == true else { return event }
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

extension HotKeyCombo {
    var eventModifiers: SwiftUI.EventModifiers {
        var result: SwiftUI.EventModifiers = []
        if contains(UInt32(cmdKey)) { result.insert(.command) }
        if contains(UInt32(shiftKey)) { result.insert(.shift) }
        if contains(UInt32(optionKey)) { result.insert(.option) }
        if contains(UInt32(controlKey)) { result.insert(.control) }
        return result
    }

    var keyEquivalent: KeyEquivalent? {
        switch keyCode {
        case UInt32(kVK_Space): return " "
        case UInt32(kVK_Tab): return "\t"
        case UInt32(kVK_Return): return "\r"
        case UInt32(kVK_Delete): return KeyEquivalent.delete
        case UInt32(kVK_Escape): return KeyEquivalent.escape
        case UInt32(kVK_LeftArrow): return KeyEquivalent.leftArrow
        case UInt32(kVK_RightArrow): return KeyEquivalent.rightArrow
        case UInt32(kVK_UpArrow): return KeyEquivalent.upArrow
        case UInt32(kVK_DownArrow): return KeyEquivalent.downArrow
        default:
            guard let name = Self.ansiCharacters[keyCode], let character = name.first else {
                return nil
            }
            return KeyEquivalent(character)
        }
    }

    private static let ansiCharacters: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "a", UInt32(kVK_ANSI_B): "b", UInt32(kVK_ANSI_C): "c",
        UInt32(kVK_ANSI_D): "d", UInt32(kVK_ANSI_E): "e", UInt32(kVK_ANSI_F): "f",
        UInt32(kVK_ANSI_G): "g", UInt32(kVK_ANSI_H): "h", UInt32(kVK_ANSI_I): "i",
        UInt32(kVK_ANSI_J): "j", UInt32(kVK_ANSI_K): "k", UInt32(kVK_ANSI_L): "l",
        UInt32(kVK_ANSI_M): "m", UInt32(kVK_ANSI_N): "n", UInt32(kVK_ANSI_O): "o",
        UInt32(kVK_ANSI_P): "p", UInt32(kVK_ANSI_Q): "q", UInt32(kVK_ANSI_R): "r",
        UInt32(kVK_ANSI_S): "s", UInt32(kVK_ANSI_T): "t", UInt32(kVK_ANSI_U): "u",
        UInt32(kVK_ANSI_V): "v", UInt32(kVK_ANSI_W): "w", UInt32(kVK_ANSI_X): "x",
        UInt32(kVK_ANSI_Y): "y", UInt32(kVK_ANSI_Z): "z",
        UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_ANSI_Minus): "-", UInt32(kVK_ANSI_Equal): "=",
        UInt32(kVK_ANSI_LeftBracket): "[", UInt32(kVK_ANSI_RightBracket): "]",
        UInt32(kVK_ANSI_Backslash): "\\", UInt32(kVK_ANSI_Semicolon): ";",
        UInt32(kVK_ANSI_Quote): "'", UInt32(kVK_ANSI_Grave): "`",
        UInt32(kVK_ANSI_Comma): ",", UInt32(kVK_ANSI_Period): ".",
        UInt32(kVK_ANSI_Slash): "/"
    ]
}
