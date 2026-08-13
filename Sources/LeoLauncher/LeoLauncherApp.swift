import AppKit
import SwiftUI

@main
struct LeoLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("LeoLauncher", systemImage: "square.grid.2x2") {
            Button("显示启动器") {
                appDelegate.showLauncher()
            }
            .keyboardShortcut(" ", modifiers: [.option])
            Button("设置…") {
                appDelegate.openSettings()
            }
            Divider()
            Button("重新扫描应用") {
                LauncherStore.shared.refreshApps()
            }
            Button("对未知应用分类") {
                LauncherStore.shared.reclassifyUnknown()
            }
            Divider()
            Button("退出 LeoLauncher") {
                NSApp.terminate(nil)
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(store: LauncherStore.shared)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlay = OverlayController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        overlay.bind(store: LauncherStore.shared)
        HotKeyCenter.shared.onMain = { [weak self] in
            self?.overlay.toggle()
        }
        HotKeyCenter.shared.onSearch = { [weak self] in
            self?.overlay.show(focusSearch: true)
        }
        HotKeyCenter.shared.registerDefaults()
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        Task { await LauncherStore.shared.boot() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        overlay.show()
        return false
    }

    func showLauncher() {
        overlay.show()
    }

    func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        guard let raw = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: raw) else { return }
        Task { @MainActor in
            switch url.host {
            case "search":
                if let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "q" })?.value {
                    LauncherStore.shared.query = query
                }
                self.overlay.show(focusSearch: true)
            default:
                self.overlay.show()
            }
        }
    }
}
