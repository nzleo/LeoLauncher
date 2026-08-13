import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

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
        .frame(width: 620, height: 620)
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
        AppearancePane(store: store)
    }

    private var shortcuts: some View {
        Form {
            LabeledContent("主界面") { Text("⌥ Space  或  ⌥⇧ Space") }
            LabeledContent("搜索优先") { Text("⌃ Space") }
            LabeledContent("关闭") { Text("Esc 或点击空白") }
            LabeledContent("搜索") { Text("打开后直接打字，支持拼音") }
            LabeledContent("打开选中") { Text("Enter") }
            LabeledContent("排序") { Text("右上角：分类 / 颜色 / 时间") }
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

private struct AppearancePane: View {
    @Bindable var store: LauncherStore
    @State private var pickingWallpaper = false

    var body: some View {
        Form {
            Section("启动器背景") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                    ForEach(OverlayStyle.allCases) { style in
                        StylePreviewCard(
                            style: style,
                            selected: store.overlayStyle == style
                        ) {
                            store.updateOverlayStyle(style)
                        }
                    }
                }
                .padding(.vertical, 4)
                Text("玻璃和毛玻璃会透出桌面；墨色是夜间深色面板。打开启动器即可立刻看到效果。")
                    .foregroundStyle(.secondary)
            }

            Section("墙纸") {
                HStack(alignment: .center, spacing: 14) {
                    wallpaperThumb
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button(store.wallpaperImage == nil ? "选择墙纸…" : "更换墙纸…") {
                                pickingWallpaper = true
                            }
                            if store.wallpaperImage != nil {
                                Button("清除", role: .destructive) {
                                    store.clearWallpaper()
                                }
                            }
                        }
                        Text("半透明叠在桌面上，可和上面四种背景一起用。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                if store.wallpaperImage != nil {
                    LabeledContent("墙纸浓度") {
                        Slider(
                            value: Binding(
                                get: { store.wallpaperOpacity },
                                set: { store.updateWallpaperOpacity($0) }
                            ),
                            in: 0.2...0.9,
                            step: 0.05
                        )
                        .frame(width: 180)
                        Text("\(Int(store.wallpaperOpacity * 100))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }

            Section("左上角") {
                LabeledContent("招呼语") {
                    HStack {
                        TextField("嗨 \(SystemIdentity.preferredName)", text: Binding(
                            get: { store.greeting },
                            set: { store.updateGreeting($0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                        if store.usesCustomGreeting {
                            Button("用系统名字") {
                                store.resetGreeting()
                            }
                        }
                    }
                }
                Text("默认读取这台 Mac 的用户全名（不是电脑名，也不是写死的 Leo）。现在识别为「\(SystemIdentity.preferredName)」。")
                    .foregroundStyle(.secondary)
            }

            Section("世界名言") {
                Toggle("打开启动器时显示一句名言", isOn: Binding(
                    get: { store.quoteMode != .off },
                    set: { store.updateQuoteMode($0 ? .both : .off) }
                ))
                if store.quoteMode != .off {
                    Picker("语言", selection: Binding(
                        get: { store.quoteMode },
                        set: { store.updateQuoteMode($0) }
                    )) {
                        Text("中英双语").tag(QuoteMode.both)
                        Text("仅中文").tag(QuoteMode.chinese)
                        Text("仅英文").tag(QuoteMode.english)
                    }
                    .pickerStyle(.segmented)
                    Picker("位置", selection: Binding(
                        get: { store.quotePlacement },
                        set: { store.updateQuotePlacement($0) }
                    )) {
                        ForEach(QuotePlacement.allCases) { placement in
                            Text(placement.title).tag(placement)
                        }
                    }
                    Text("顶部会跟在「\(store.greeting)」下面；也可以改到最底下的分类索引上方。每次打开换一句。")
                        .foregroundStyle(.secondary)
                }
            }

            Section("设置窗口") {
                Picker("配色", selection: Binding(
                    get: { store.state.appearance },
                    set: { store.updateAppearance($0) }
                )) {
                    Text("跟随系统").tag("system")
                    Text("深色").tag("dark")
                    Text("浅色").tag("light")
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .padding()
        .fileImporter(
            isPresented: $pickingWallpaper,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                store.importWallpaper(from: url)
            }
        }
    }

    @ViewBuilder
    private var wallpaperThumb: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
            if let image = store.wallpaperImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 72, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
        }
    }
}

private struct StylePreviewCard: View {
    var style: OverlayStyle
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomLeading) {
                    preview
                    VStack(alignment: .leading, spacing: 3) {
                        Capsule().fill(.white.opacity(0.55)).frame(width: 28, height: 4)
                        HStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.35)).frame(width: 10, height: 10)
                            RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.28)).frame(width: 10, height: 10)
                            RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.2)).frame(width: 10, height: 10)
                        }
                    }
                    .padding(8)
                }
                .frame(height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(selected ? Ink.copper : Color.secondary.opacity(0.25), lineWidth: selected ? 2 : 1)
                }

                Text(style.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(style.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? Ink.copper.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .help(style.subtitle)
    }

    @ViewBuilder
    private var preview: some View {
        switch style {
        case .glass:
            LinearGradient(
                colors: [
                    Color(red: 0.72, green: 0.84, blue: 0.92).opacity(0.85),
                    Color(red: 0.55, green: 0.62, blue: 0.78).opacity(0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(Color.white.opacity(0.28))
        case .frosted:
            LinearGradient(
                colors: [
                    Color(red: 0.42, green: 0.46, blue: 0.52),
                    Color(red: 0.22, green: 0.24, blue: 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(Color.white.opacity(0.12))
        case .transparent:
            Checkerboard()
                .opacity(0.55)
                .background(Color(red: 0.35, green: 0.55, blue: 0.42))
        case .ink:
            Ink.paper
                .overlay(
                    RadialGradient(
                        colors: [Ink.copper.opacity(0.35), .clear],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 70
                    )
                )
        }
    }
}

private struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 7
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var col = 0
                while x < size.width {
                    if (row + col).isMultiple(of: 2) {
                        context.fill(
                            Path(CGRect(x: x, y: y, width: cell, height: cell)),
                            with: .color(.white.opacity(0.28))
                        )
                    }
                    x += cell
                    col += 1
                }
                y += cell
                row += 1
            }
        }
    }
}
