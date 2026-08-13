import AppKit
import Carbon
import Foundation

final class HotKeyCenter: @unchecked Sendable {
    static let shared = HotKeyCenter()

    var onMain: (() -> Void)?
    var onSearch: (() -> Void)?

    private var handler: EventHandlerRef?
    private var mainRef: EventHotKeyRef?
    private var searchRef: EventHotKeyRef?
    private let signature: OSType = 0x4C4C484B // 'LLHK'

    func registerDefaults() {
        installHandlerIfNeeded()
        register(id: 1, keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey), slot: &mainRef)
        register(id: 2, keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey | shiftKey), slot: &mainRef)
        register(id: 3, keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey), slot: &searchRef)
    }

    func handle(id: UInt32) {
        Task { @MainActor in
            switch id {
            case 1, 2:
                self.onMain?()
            case 3:
                self.onSearch?()
            default:
                break
            }
        }
    }

    private func installHandlerIfNeeded() {
        guard handler == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                DispatchQueue.main.async {
                    HotKeyCenter.shared.handle(id: hotKeyID.id)
                }
                return noErr
            },
            1,
            &spec,
            nil,
            &handler
        )
        if status != noErr {
            NSLog("LeoLauncher hotkey handler failed: \(status)")
        }
    }

    private func register(id: UInt32, keyCode: UInt32, modifiers: UInt32, slot: inout EventHotKeyRef?) {
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        if status == noErr {
            slot = ref
        } else {
            NSLog("LeoLauncher hotkey \(id) failed: \(status)")
        }
    }
}
