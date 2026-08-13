import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Bindable var store: LauncherStore

    var body: some View {
        TabView {
            general.tabItem { Label("通用", systemImage: "gear") }
            appearance.tabItem { Label("外观", systemImage: "paintpalette") }
            shortcuts.tabItem { Label("快捷键", systemImage: "keyboard") }
            categories.tabItem { Label("分类", systemImage: "tag") }
            sync.tabItem { Label("同步", systemImage: "icloud") }
            about.tabItem { Label("关于", systemImage: "info.circle") }
        }
        .frame(width: 560, height: 480)
    }

    private var general: some View {
        Form {
            Toggle("登录时启动", isOn: Binding(
                get: { store.state.launchAtLogin },
                set: { store.updateLaunchAtLogin($0) }
            ))
            Toggle("在 Dock 中显示", isOn: Binding(
                get: { store.state.showInDock },
                set: { store.updateShowInDock($0) }
            ))
            Toggle("隐藏应用名称", isOn: Binding(
                get: { store.state.hideAppNames },
                set: { store.updateHideNames($0) }
            ))
            Toggle("显示不常用系统工具", isOn: Binding(
                get: { store.state.showObscureSystemApps },
                set: { store.updateShowObscure($0) }
            ))
            LabeledContent("图标大小") {
                Slider(value: Binding(
                    get: { store.state.iconSize },
                    set: { store.updateIconSize($0) }
                ), in: 44...72, step: 4)
                .frame(width: 180)
                Text("\(Int(store.state.iconSize))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var appearance: some View {
        Form {
            Picker("外观", selection: Binding(
                get: { store.state.appearance },
                set: { store.updateAppearance($0) }
            )) {
                Text("跟随系统").tag("system")
                Text("深色").tag("dark")
                Text("浅色").tag("light")
            }
            .pickerStyle(.segmented)
            Text("三列瀑布流，栏目等宽、自上而下填满，不再用大小不一的玻璃块。拖到分区即可改分类。")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding()
    }

    private var shortcuts: some View {
        Form {
            LabeledContent("主界面") { Text("⌥ Space  或  ⌥⇧ Space") }
            LabeledContent("搜索优先") { Text("⌃ Space") }
            LabeledContent("关闭") { Text("Esc") }
            LabeledContent("打开选中") { Text("Enter") }
            LabeledContent("URL Scheme") { Text("leolauncher://show") }
            Text("触控板手势可绑定到 leolauncher://show，兼容 BetterTouchTool / TourBox。")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding()
    }

    private var categories: some View {
        List {
            ForEach(store.grouped, id: \.0) { category, apps in
                Section(category.title) {
                    ForEach(apps) { app in
                        HStack {
                            Image(nsImage: IconCache.shared.image(for: app.url, pointSize: 24))
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text(app.name)
                            Spacer()
                            Text(sourceLabel(app.source))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contextMenu {
                            ForEach(AppCategory.boardOrder) { item in
                                Button(item.title) { store.reassign(app, to: item) }
                            }
                            Button("隐藏", role: .destructive) { store.hideApp(app) }
                        }
                    }
                }
            }
            if !store.state.hiddenBundleIDs.isEmpty {
                Section("已隐藏") {
                    ForEach(store.state.hiddenBundleIDs, id: \.self) { id in
                        HStack {
                            Text(store.apps.first(where: { $0.bundleID == id })?.name ?? id)
                            Spacer()
                            Button("恢复") { store.unhide(id) }
                        }
                    }
                }
            }
        }
    }

    private var sync: some View {
        Form {
            LabeledContent("iCloud") {
                Text(store.iCloudAvailable ? "已登录，分类随 Apple 账号同步" : "未检测到 iCloud 云盘")
            }
            LabeledContent("最近同步") {
                Text(store.lastSyncedAt?.formatted(date: .omitted, time: .standard) ?? "尚未同步")
            }
            Button("立即同步") {
                store.persistNow()
            }
            Button("从 iCloud 重新加载") {
                Task { await store.reloadFromCloud() }
            }
            Button(store.isClassifying ? "正在智能分类…" : "对未知应用重新分类") {
                store.reclassifyUnknown()
            }
            .disabled(store.isClassifying)
            Text("分类按 Bundle ID 存储，不会因为换机器、换路径而丢失。两台 Mac 登录同一 iCloud 即可共用分区。")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding()
    }

    private var about: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
            Text("LeoLauncher")
                .font(LeoFont.title(22))
            Text("空间分区启动器")
                .foregroundStyle(.secondary)
            Text("版本 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("每个应用只进一个分区。拖一下就能改。iCloud 跟着走。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding(.top, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sourceLabel(_ source: ClassificationSource) -> String {
        switch source {
        case .user: "手动"
        case .catalog: "目录"
        case .heuristic: "规则"
        case .itunes: "商店"
        case .model: "模型"
        case .fallback: "待分"
        }
    }
}
