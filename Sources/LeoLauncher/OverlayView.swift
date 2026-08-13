import AppKit
import SwiftUI

struct OverlayView: View {
    @Bindable var store: LauncherStore
    var onDismiss: () -> Void
    @State private var hoveredID: String?
    @State private var dropCategory: AppCategory?
    @State private var focusedCategory: AppCategory?

    var body: some View {
        ZStack {
            background
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 0) {
                chrome
                    .padding(.horizontal, 36)
                    .padding(.top, 26)
                    .padding(.bottom, 18)

                if store.query.isEmpty {
                    masonryBoard
                } else {
                    searchResults
                }

                indexBar
                    .padding(.horizontal, 36)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
            }
        }
        .foregroundStyle(Ink.ivory)
        .onExitCommand(perform: handleEscape)
        .focusable()
        .onKeyPress { press in
            handle(press)
        }
    }

    private var background: some View {
        ZStack {
            VisualBlur(material: .underWindowBackground, blending: .behindWindow)
            Ink.paper.opacity(0.72)
            RadialGradient(
                colors: [Ink.copper.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 640
            )
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var chrome: some View {
        HStack(alignment: .firstTextBaseline, spacing: 22) {
            Text("Leo")
                .font(LeoFont.display(34))
                .italic()
                .foregroundStyle(Ink.ivory)

            Rectangle()
                .fill(Ink.copper)
                .frame(width: 28, height: 1)
                .offset(y: -6)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Ink.mute)
                TextField("搜索应用、拼音、分类", text: $store.query)
                    .textFieldStyle(.plain)
                    .font(LeoFont.body(16))
                    .foregroundStyle(Ink.ivory)
            }

            Spacer(minLength: 12)

            if store.isClassifying {
                ProgressView()
                    .controlSize(.small)
            }
            Text(store.iCloudAvailable ? "iCloud" : "本机")
                .font(LeoFont.mono(11))
                .foregroundStyle(Ink.mute)
                .tracking(1.4)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Ink.line)
                .frame(height: 1)
                .offset(y: 12)
        }
    }

    private var masonryBoard: some View {
        GeometryReader { geo in
            let columns = Masonry.columnCount(for: geo.size.width)
            let groups = Masonry.distribute(store.grouped, into: columns)
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
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
                                            onLaunch: store.launch
                                        )
                                        .id(category)
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
                .onChange(of: focusedCategory) { _, category in
                    guard let category else { return }
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo(category, anchor: .top)
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
                .foregroundStyle(Ink.mute)
            HStack(spacing: 8) {
                ForEach(store.recents) { app in
                    AppTile(
                        app: app,
                        size: store.iconSize,
                        hideName: true,
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
            .padding(.horizontal, 36)
            .padding(.bottom, 24)
        }
    }

    private var indexBar: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(store.grouped.enumerated()), id: \.element.0) { index, pair in
                        if index > 0 {
                            Text("·")
                                .foregroundStyle(Ink.mute)
                                .padding(.horizontal, 8)
                        }
                        Button {
                            store.query = ""
                            focusedCategory = pair.0
                        } label: {
                            Text(pair.0.title)
                                .font(LeoFont.title(13))
                                .foregroundStyle(focusedCategory == pair.0 ? Ink.copper : Ink.ivory.opacity(0.78))
                        }
                        .buttonStyle(.plain)
                        .dropDestination(for: String.self) { items, _ in
                            drop(items, onto: pair.0)
                        }
                    }
                }
            }
            Text("⌥ Space")
                .font(LeoFont.mono(10))
                .foregroundStyle(Ink.mute)
                .padding(.leading, 16)
        }
        .padding(.top, 10)
        .overlay(alignment: .top) {
            Rectangle().fill(Ink.line).frame(height: 1)
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
    var onLaunch: (AppRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(category.title)
                    .font(LeoFont.title(18))
                Text("\(apps.count)")
                    .font(LeoFont.mono(11))
                    .foregroundStyle(Ink.mute)
                Spacer(minLength: 0)
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(highlighted ? Ink.copper : category.tint.opacity(0.85))
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
        .background(Ink.panel.opacity(highlighted ? 0.96 : 0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(highlighted ? Ink.copper.opacity(0.8) : Ink.line, lineWidth: 1)
        }
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

    var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 5) {
                Image(nsImage: IconCache.shared.image(for: app.url, pointSize: size))
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size, height: size)
                    .scaleEffect(hovered || selected ? 1.06 : 1)
                if !hideName {
                    Text(app.name)
                        .font(LeoFont.body(10))
                        .foregroundStyle(Ink.ivory.opacity(0.78))
                        .lineLimit(1)
                        .frame(width: size + 14)
                }
            }
            .padding(5)
            .background {
                if selected || hovered {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Ink.copper.opacity(0.14))
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
