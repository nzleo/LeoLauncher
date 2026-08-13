import AppKit
import SwiftUI

struct OverlayView: View {
    @Bindable var store: LauncherStore
    var onDismiss: () -> Void
    @State private var hoveredID: String?
    @State private var dropCategory: AppCategory?
    @State private var focusedSection: String?
    @State private var jumpToken = 0
    @State private var pulseSection: String?
    @FocusState private var searchFocused: Bool

    private var palette: OverlayPalette { OverlayPalette.make(store.overlayStyle) }
    private var showsQuote: Bool {
        store.quoteMode != .off && store.query.isEmpty
    }

    var body: some View {
        ZStack {
            OverlayBackdrop(
                style: store.overlayStyle,
                wallpaper: store.wallpaperImage,
                wallpaperOpacity: store.wallpaperOpacity
            )
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 0) {
                chrome
                    .zIndex(10)
                    .padding(.horizontal, 36)
                    .padding(.top, 26)
                    .padding(.bottom, 18)

                if store.query.isEmpty {
                    board
                } else {
                    searchResults
                }

                indexBar
                    .padding(.horizontal, 36)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
            }
            .padding(.top, store.screenInsets.top)
            .padding(.leading, store.screenInsets.leading)
            .padding(.bottom, store.screenInsets.bottom)
            .padding(.trailing, store.screenInsets.trailing)
        }
        .foregroundStyle(palette.text)
        .environment(\.overlayPalette, palette)
        .onAppear { searchFocused = true }
        .onChange(of: store.focusTick) {
            searchFocused = true
        }
        .onChange(of: store.isVisible) { _, visible in
            if visible { searchFocused = true }
        }
        .onChange(of: store.sortMode) {
            focusedSection = nil
            pulseSection = nil
        }
        .onExitCommand(perform: handleEscape)
        .focusable()
        .onKeyPress { press in
            handle(press)
        }
    }

    private var chrome: some View {
        HStack(alignment: .center, spacing: 18) {
            Text(store.greeting)
                .font(LeoFont.display(30))
                .italic()
                .foregroundStyle(palette.text)
                .shadow(color: .black.opacity(0.45), radius: 8, y: 1)
                .lineLimit(1)

            Rectangle()
                .fill(Ink.copper)
                .frame(width: 22, height: 1)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.mute)
                TextField("直接打字搜索，支持拼音", text: $store.query)
                    .textFieldStyle(.plain)
                    .font(LeoFont.body(16))
                    .foregroundStyle(palette.text)
                    .focused($searchFocused)
                    .onSubmit { store.launchSelected() }
            }
            .frame(maxWidth: 520, alignment: .leading)

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                ForEach(SortMode.allCases) { mode in
                    ChromeButton(
                        symbol: mode.symbol,
                        selected: store.sortMode == mode,
                        help: mode.help
                    ) {
                        store.updateSortMode(mode)
                    }
                }
                ChromeButton(symbol: "gearshape", selected: false, help: "设置") {
                    openSettings()
                }
            }
            .fixedSize()
            .layoutPriority(1)

            if store.isClassifying {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(palette.line)
                .frame(height: 1)
                .offset(y: 12)
        }
    }

    private func openSettings() {
        AppDelegate.shared?.openSettings()
    }

    @ViewBuilder
    private var board: some View {
        switch store.sortMode {
        case .function:
            masonryBoard
        case .color:
            ColorSpectrumBoard(
                groups: store.colorGroups,
                store: store,
                hoveredID: $hoveredID,
                focused: $focusedSection,
                jumpToken: jumpToken,
                pulseSection: pulseSection,
                onDismiss: onDismiss,
                onLaunch: store.launch
            )
        case .time:
            TimeLaneBoard(
                groups: store.timeGroups,
                store: store,
                hoveredID: $hoveredID,
                focused: $focusedSection,
                jumpToken: jumpToken,
                pulseSection: pulseSection,
                onDismiss: onDismiss,
                onLaunch: store.launch
            )
        }
    }

    private var masonryBoard: some View {
        GeometryReader { geo in
            let columns = Masonry.columnCount(for: geo.size.width)
            let groups = Masonry.distribute(store.grouped, into: columns)
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .top) {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: geo.size.height)
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onDismiss)
                        VStack(alignment: .leading, spacing: 22) {
                            if !store.recents.isEmpty {
                                recentsRail
                            }
                            HStack(alignment: .top, spacing: 18) {
                                ForEach(Array(groups.enumerated()), id: \.offset) { _, column in
                                    VStack(spacing: 18) {
                                        ForEach(column, id: \.0) { category, apps in
                                            CategoryColumn(
                                                category: category,
                                                apps: apps,
                                                store: store,
                                                hoveredID: $hoveredID,
                                                highlighted: dropCategory == category,
                                                emphasized: pulseSection == category.rawValue,
                                                onLaunch: store.launch
                                            )
                                            .id(category.rawValue)
                                            .dropDestination(for: String.self) { items, _ in
                                                drop(items, onto: category)
                                            } isTargeted: { hovering in
                                                dropCategory = hovering ? category : nil
                                            }
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .top)
                                }
                            }
                        }
                        .padding(.horizontal, 36)
                        .padding(.bottom, 24)
                    }
                }
                .onChange(of: jumpToken) {
                    guard let id = focusedSection else { return }
                    withAnimation(.easeOut(duration: 0.22)) {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
    }

    private var recentsRail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最近")
                .font(LeoFont.mono(11))
                .tracking(2)
                .foregroundStyle(palette.mute)
            HStack(spacing: 8) {
                ForEach(store.recents) { app in
                    AppTile(
                        app: app,
                        size: store.iconSize,
                        hideName: store.hideAppNames,
                        selected: store.selectedID == app.id,
                        hovered: hoveredID == app.id,
                        onLaunch: { store.launch(app) },
                        onHover: { hoveredID = $0 ? app.id : nil }
                    )
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var searchResults: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 240)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onDismiss)
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(store.filtered.count) 个结果")
                        .font(LeoFont.mono(11))
                        .foregroundStyle(palette.mute)
                        .tracking(1)
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: store.iconSize + 28), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(store.filtered) { app in
                            AppTile(
                                app: app,
                                size: store.iconSize,
                                hideName: store.hideAppNames,
                                selected: store.selectedID == app.id,
                                hovered: hoveredID == app.id,
                                onLaunch: { store.launch(app) },
                                onHover: { hoveredID = $0 ? app.id : nil }
                            )
                            .contextMenu { appMenu(app) }
                        }
                    }
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 24)
            }
        }
    }

    private var indexBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(indexItems, id: \.id) { item in
                            let active = focusedSection == item.id || pulseSection == item.id
                            Button {
                                jump(to: item.id)
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(item.tint)
                                        .frame(width: 8, height: 8)
                                        .shadow(color: item.tint.opacity(active ? 0.8 : 0), radius: active ? 5 : 0)
                                    Text(item.title)
                                        .font(LeoFont.title(13))
                                }
                                .foregroundStyle(active ? item.tint : palette.text.opacity(0.8))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(item.tint.opacity(active ? 0.28 : 0.08))
                                )
                                .overlay {
                                    Capsule(style: .continuous)
                                        .strokeBorder(item.tint.opacity(active ? 0.95 : 0.18), lineWidth: active ? 1.2 : 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .help(item.title)
                            .dropDestination(for: String.self) { items, _ in
                                guard store.sortMode == .function,
                                      let category = AppCategory(rawValue: item.id) else { return false }
                                return drop(items, onto: category)
                            }
                        }
                    }
                }
                Text(store.iCloudAvailable ? "iCloud" : "本机")
                    .font(LeoFont.mono(10))
                    .foregroundStyle(palette.mute)
                    .padding(.leading, 16)
                Text("Esc 关闭")
                    .font(LeoFont.mono(10))
                    .foregroundStyle(palette.mute)
                    .padding(.leading, 12)
            }

            if showsQuote {
                QuoteFooter(quote: store.currentQuote, mode: store.quoteMode)
            }
        }
        .padding(.top, 10)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.line).frame(height: 1)
        }
    }

    private func jump(to id: String) {
        store.query = ""
        focusedSection = id
        pulseSection = id
        jumpToken += 1
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1200))
            if pulseSection == id {
                withAnimation(.easeOut(duration: 0.25)) {
                    pulseSection = nil
                }
            }
        }
    }

    private var indexItems: [(id: String, title: String, tint: Color)] {
        switch store.sortMode {
        case .function:
            store.grouped.map { ($0.0.rawValue, $0.0.title, $0.0.tint) }
        case .color:
            store.colorGroups.map { ($0.0.rawValue, $0.0.title, $0.0.tint) }
        case .time:
            store.timeGroups.map { ($0.0.id, $0.0.title, $0.0.tint) }
        }
    }

    @ViewBuilder
    private func appMenu(_ app: AppRecord) -> some View {
        Button("打开") { store.launch(app) }
        Button("在 Finder 中显示") { store.reveal(app) }
        Divider()
        Menu("移到分类") {
            ForEach(AppCategory.boardOrder) { category in
                Button(category.title) {
                    store.reassign(app, to: category)
                }
            }
        }
        Button("从启动器隐藏", role: .destructive) {
            store.hideApp(app)
        }
    }

    private func drop(_ items: [String], onto category: AppCategory) -> Bool {
        guard let bundleID = items.first,
              let app = store.apps.first(where: { $0.bundleID == bundleID }) else { return false }
        store.reassign(app, to: category)
        dropCategory = nil
        return true
    }

    private func handleEscape() {
        if !store.query.isEmpty {
            store.query = ""
        } else {
            onDismiss()
        }
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .escape:
            handleEscape()
            return .handled
        case .return:
            store.launchSelected()
            return .handled
        case .upArrow:
            store.moveSelection(-1)
            return .handled
        case .downArrow:
            store.moveSelection(1)
            return .handled
        case .leftArrow:
            store.moveSelection(-1)
            return .handled
        case .rightArrow:
            store.moveSelection(1)
            return .handled
        default:
            return .ignored
        }
    }
}

struct CategoryColumn: View {
    var category: AppCategory
    var apps: [AppRecord]
    var store: LauncherStore
    @Binding var hoveredID: String?
    var highlighted: Bool
    var emphasized: Bool
    var onLaunch: (AppRecord) -> Void
    @Environment(\.overlayPalette) private var palette

    private var lit: Bool { highlighted || emphasized }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(category.title)
                    .font(LeoFont.title(18))
                    .foregroundStyle(lit ? category.tint : palette.text)
                Text("\(apps.count)")
                    .font(LeoFont.mono(11))
                    .foregroundStyle(palette.mute)
                Spacer(minLength: 0)
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(lit ? category.tint : category.tint.opacity(0.85))
                    .frame(width: 2, height: 14)
                    .offset(x: -10)
            }

            IconFlow(
                apps: apps,
                iconSize: store.iconSize,
                hideNames: store.hideAppNames,
                selectedID: store.selectedID,
                hoveredID: hoveredID,
                onLaunch: onLaunch,
                onHover: { hoveredID = $0 }
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            ZStack {
                if palette.usesMaterial {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(lit ? category.tint.opacity(0.22) : palette.panelFill)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(lit ? category.tint.opacity(0.95) : palette.panelStroke, lineWidth: lit ? 1.6 : 1)
        }
        .shadow(color: category.tint.opacity(emphasized ? 0.45 : 0), radius: emphasized ? 18 : 0)
        .scaleEffect(emphasized ? 1.03 : 1)
        .animation(.spring(duration: 0.28, bounce: 0.18), value: emphasized)
    }
}

struct IconFlow: View {
    var apps: [AppRecord]
    var iconSize: CGFloat
    var hideNames: Bool
    var selectedID: String?
    var hoveredID: String?
    var onLaunch: (AppRecord) -> Void
    var onHover: (String?) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: iconSize + (hideNames ? 8 : 16)), spacing: 6)],
            alignment: .leading,
            spacing: 6
        ) {
            ForEach(apps) { app in
                AppTile(
                    app: app,
                    size: iconSize,
                    hideName: hideNames,
                    selected: selectedID == app.id,
                    hovered: hoveredID == app.id,
                    onLaunch: { onLaunch(app) },
                    onHover: { onHover($0 ? app.id : nil) }
                )
                .draggable(app.bundleID)
                .zIndex(hoveredID == app.id ? 10 : 0)
                .contextMenu {
                    Button("打开") { onLaunch(app) }
                    Button("在 Finder 中显示") { LauncherStore.shared.reveal(app) }
                    Divider()
                    Menu("移到分类") {
                        ForEach(AppCategory.boardOrder) { category in
                            Button(category.title) {
                                LauncherStore.shared.reassign(app, to: category)
                            }
                        }
                    }
                    Button("从启动器隐藏", role: .destructive) {
                        LauncherStore.shared.hideApp(app)
                    }
                }
            }
        }
    }
}

struct AppTile: View {
    var app: AppRecord
    var size: CGFloat
    var hideName: Bool
    var selected: Bool
    var hovered: Bool
    var onLaunch: () -> Void
    var onHover: (Bool) -> Void
    @Environment(\.overlayPalette) private var palette

    var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 5) {
                ZStack(alignment: .bottom) {
                    Image(nsImage: IconCache.shared.image(for: app.url, pointSize: size))
                        .resizable()
                        .interpolation(.high)
                        .frame(width: size, height: size)
                        .scaleEffect(hovered || selected ? 1.06 : 1)
                        .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
                    if hideName, hovered || selected {
                        Text(app.name)
                            .font(LeoFont.body(10))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule(style: .continuous).fill(.black.opacity(0.78)))
                            .offset(y: 8)
                    }
                }
                .zIndex(hovered || selected ? 1 : 0)
                if !hideName {
                    Text(app.name)
                        .font(LeoFont.body(10))
                        .foregroundStyle(palette.text.opacity(0.86))
                        .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                        .lineLimit(1)
                        .frame(width: size + 14)
                }
            }
            .padding(5)
            .padding(.bottom, hideName && (hovered || selected) ? 10 : 0)
            .background {
                if selected || hovered {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Ink.copper.opacity(0.18))
                }
            }
        }
        .buttonStyle(.plain)
        .help(app.name)
        .onHover(perform: onHover)
        .animation(.easeOut(duration: 0.08), value: hovered)
        .animation(.easeOut(duration: 0.08), value: selected)
        .accessibilityLabel(app.name)
    }
}

struct ChromeButton: View {
    var symbol: String
    var selected: Bool
    var help: String
    var action: () -> Void
    @Environment(\.overlayPalette) private var palette

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(selected ? Ink.paper : palette.text.opacity(0.9))
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(selected ? Ink.copper : palette.chromeIdle)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(selected ? Ink.copper : palette.line, lineWidth: 1)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(TapGesture().onEnded { action() })
            .help(help)
            .accessibilityLabel(help)
            .accessibilityAddTraits(.isButton)
    }
}
