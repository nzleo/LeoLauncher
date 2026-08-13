import AppKit
import Carbon
import Foundation

struct HotKeyCombo: Codable, Equatable, Hashable, Sendable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultMain = HotKeyCombo(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey))
    static let defaultMainAlternate = HotKeyCombo(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey | shiftKey))
    static let defaultSearch = HotKeyCombo(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey))
    static let escapeKeyCode: UInt16 = UInt16(kVK_Escape)

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(event: NSEvent) {
        let modifierKeyCodes: Set<UInt16> = [
            UInt16(kVK_Command), UInt16(kVK_RightCommand),
            UInt16(kVK_Shift), UInt16(kVK_RightShift),
            UInt16(kVK_Option), UInt16(kVK_RightOption),
            UInt16(kVK_Control), UInt16(kVK_RightControl),
            UInt16(kVK_CapsLock), UInt16(kVK_Function)
        ]
        guard !modifierKeyCodes.contains(event.keyCode) else { return nil }
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        self.init(keyCode: UInt32(event.keyCode), modifiers: carbon)
    }

    var display: String {
        let mods = modifierSymbols
        return mods.isEmpty ? keyName : "\(mods) \(keyName)"
    }

    var modifierSymbols: String {
        var symbols = ""
        if contains(UInt32(controlKey)) { symbols += "⌃" }
        if contains(UInt32(optionKey)) { symbols += "⌥" }
        if contains(UInt32(shiftKey)) { symbols += "⇧" }
        if contains(UInt32(cmdKey)) { symbols += "⌘" }
        return symbols
    }

    var keyName: String {
        Self.keyNames[keyCode] ?? "Key \(keyCode)"
    }

    var allowsBareKey: Bool {
        switch keyCode {
        case UInt32(kVK_F13), UInt32(kVK_F14), UInt32(kVK_F15),
             UInt32(kVK_F16), UInt32(kVK_F17), UInt32(kVK_F18),
             UInt32(kVK_F19), UInt32(kVK_F20):
            true
        default:
            false
        }
    }

    var validationError: String? {
        if keyCode == UInt32(kVK_Escape) {
            return "Esc 用来关闭启动器，不能改成全局快捷键"
        }
        let hasStrongModifier = contains(UInt32(cmdKey)) || contains(UInt32(optionKey)) || contains(UInt32(controlKey))
        if !hasStrongModifier && !allowsBareKey {
            return "请加上 ⌘、⌥ 或 ⌃，避免和平时打字冲突"
        }
        return nil
    }

    func contains(_ flag: UInt32) -> Bool {
        modifiers & flag != 0
    }

    private static let keyNames: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_Space): "Space",
        UInt32(kVK_Return): "Return",
        UInt32(kVK_Tab): "Tab",
        UInt32(kVK_Delete): "Delete",
        UInt32(kVK_ForwardDelete): "Fwd Del",
        UInt32(kVK_Home): "Home",
        UInt32(kVK_End): "End",
        UInt32(kVK_PageUp): "Page Up",
        UInt32(kVK_PageDown): "Page Down",
        UInt32(kVK_LeftArrow): "←",
        UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑",
        UInt32(kVK_DownArrow): "↓",
        UInt32(kVK_ANSI_Minus): "-",
        UInt32(kVK_ANSI_Equal): "=",
        UInt32(kVK_ANSI_LeftBracket): "[",
        UInt32(kVK_ANSI_RightBracket): "]",
        UInt32(kVK_ANSI_Backslash): "\\",
        UInt32(kVK_ANSI_Semicolon): ";",
        UInt32(kVK_ANSI_Quote): "'",
        UInt32(kVK_ANSI_Grave): "`",
        UInt32(kVK_ANSI_Comma): ",",
        UInt32(kVK_ANSI_Period): ".",
        UInt32(kVK_ANSI_Slash): "/",
        UInt32(kVK_F1): "F1", UInt32(kVK_F2): "F2", UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4", UInt32(kVK_F5): "F5", UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7", UInt32(kVK_F8): "F8", UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10", UInt32(kVK_F11): "F11", UInt32(kVK_F12): "F12",
        UInt32(kVK_F13): "F13", UInt32(kVK_F14): "F14", UInt32(kVK_F15): "F15",
        UInt32(kVK_F16): "F16", UInt32(kVK_F17): "F17", UInt32(kVK_F18): "F18",
        UInt32(kVK_F19): "F19", UInt32(kVK_F20): "F20"
    ]
}

final class HotKeyCenter: @unchecked Sendable {
    static let shared = HotKeyCenter()

    var onMain: (() -> Void)?
    var onSearch: (() -> Void)?

    private var handler: EventHandlerRef?
    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var applied: Applied?
    private let signature: OSType = 0x4C4C484B // 'LLHK'

    private struct Applied {
        var main: HotKeyCombo
        var search: HotKeyCombo
        var includeLegacyMainAlternate: Bool
    }

    func registerDefaults() {
        _ = apply(main: .defaultMain, search: .defaultSearch, includeLegacyMainAlternate: true)
    }

    @discardableResult
    func apply(main: HotKeyCombo, search: HotKeyCombo, includeLegacyMainAlternate: Bool) -> String? {
        installHandlerIfNeeded()
        let previous = applied
        if let error = registerNow(main: main, search: search, includeLegacyMainAlternate: includeLegacyMainAlternate) {
            if let previous {
                _ = registerNow(
                    main: previous.main,
                    search: previous.search,
                    includeLegacyMainAlternate: previous.includeLegacyMainAlternate
                )
            } else {
                _ = registerNow(main: .defaultMain, search: .defaultSearch, includeLegacyMainAlternate: true)
            }
            return error
        }
        applied = Applied(main: main, search: search, includeLegacyMainAlternate: includeLegacyMainAlternate)
        return nil
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

    private func registerNow(main: HotKeyCombo, search: HotKeyCombo, includeLegacyMainAlternate: Bool) -> String? {
        unregisterAll()
        guard register(id: 1, combo: main) else {
            return "无法注册主界面快捷键（\(main.display)），可能已被系统或其他应用占用"
        }
        if includeLegacyMainAlternate, main != .defaultMainAlternate, search != .defaultMainAlternate {
            _ = register(id: 2, combo: .defaultMainAlternate)
        }
        guard register(id: 3, combo: search) else {
            return "无法注册搜索快捷键（\(search.display)），可能已被系统或其他应用占用"
        }
        return nil
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

    private func register(id: UInt32, combo: HotKeyCombo) -> Bool {
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr, let ref {
            refs[id] = ref
            return true
        }
        NSLog("LeoLauncher hotkey \(id) failed: \(status)")
        return false
    }

    private func unregisterAll() {
        for (_, ref) in refs {
            UnregisterEventHotKey(ref)
        }
        refs.removeAll()
    }
}
