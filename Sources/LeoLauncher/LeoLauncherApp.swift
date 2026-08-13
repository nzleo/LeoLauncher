import AppKit
import SwiftUI

@main
struct LeoLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("LeoLauncher", systemImage: "square.grid.2x2") {
            ShowLauncherMenuButton()
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
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("设置…") {
                    appDelegate.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate?
    private let overlay = OverlayController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
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
        overlay.hide(animated: false)
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            SettingsWindowController.shared.show()
        }
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

private struct ShowLauncherMenuButton: View {
    var body: some View {
        let combo = LauncherStore.shared.mainHotKey
        if let key = combo.keyEquivalent {
            Button("显示启动器") {
                AppDelegate.shared?.showLauncher()
            }
            .keyboardShortcut(key, modifiers: combo.eventModifiers)
        } else {
            Button("显示启动器") {
                AppDelegate.shared?.showLauncher()
            }
        }
    }
}
