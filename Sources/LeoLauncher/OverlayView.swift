import AppKit
import SwiftUI

struct OverlayView: View {
    @Bindable var store: LauncherStore
    var onDismiss: () -> Void
    @State private var hoveredID: String?
    @State private var dropCategory: AppCategory?

    var body: some View {
        ZStack {
            background
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)

            GeometryReader { geo in
                let sidebar: CGFloat = 132
                let pad: CGFloat = 28
                HStack(alignment: .top, spacing: 16) {
                    board(width: max(320, geo.size.width - sidebar - pad * 2 - 16))
                    sidebarView
                        .frame(width: sidebar)
                }
                .padding(.horizontal, pad)
                .padding(.top, 22)
                .padding(.bottom, 18)
            }
        }
        .onAppear {
            if !store.onboardingDone {
                store.onboardingDone = true
            }
        }
        .onExitCommand(perform: handleEscape)
        .focusable()
        .onKeyPress { press in
            handle(press)
        }
    }

    private var background: some View {
        ZStack {
            VisualBlur(material: .fullScreenUI, blending: .behindWindow)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.28),
                    Color(red: 0.07, green: 0.10, blue: 0.18).opacity(0.22),
                    Color.black.opacity(0.32)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private func board(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            searchBar
            if store.query.isEmpty {
                if !store.recents.isEmpty {
                    RecentsRow(
                        apps: store.recents,
                        store: store,
                        hoveredID: $hoveredID,
                        onLaunch: store.launch
                    )
                }
                zoneBoard(width: width)
            } else {
                searchResults
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            TextField("搜索应用、拼音或分类", text: $store.query)
                .textFieldStyle(.plain)
                .font(LeoFont.title(18))
                .foregroundStyle(.white)
            if !store.query.isEmpty {
                Text("\(store.filtered.count)")
                    .font(LeoFont.body(12))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .leoGlass(cornerRadius: 16)
    }

    private func zoneBoard(width: CGFloat) -> some View {
        let zones = ZonePacker.pack(
            groups: store.grouped,
            width: width,
            iconSize: store.iconSize,
            hideNames: store.hideAppNames
        )
        let height = max(ZonePacker.boardHeight(zones: zones), 200)

        return ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                ForEach(zones) { zone in
                    ZoneCard(
                        zone: zone,
                        store: store,
                        hoveredID: $hoveredID,
                        highlighted: dropCategory == zone.category,
                        onLaunch: store.launch
                    )
                    .frame(width: zone.rect.width, height: zone.rect.height, alignment: .topLeading)
                    .offset(x: zone.rect.minX, y: zone.rect.minY)
                    .dropDestination(for: String.self) { items, _ in
                        drop(items, onto: zone.category)
                    } isTargeted: { hovering in
                        dropCategory = hovering ? zone.category : nil
                    }
                }
            }
            .frame(width: width, height: height, alignment: .topLeading)
            .padding(.bottom, 40)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var searchResults: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: store.iconSize + 28), spacing: 12)],
                spacing: 12
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
            .padding(16)
            .leoGlass(cornerRadius: 22)
        }
    }

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                if store.isClassifying {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.bottom, 4)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(store.grouped, id: \.0) { category, apps in
                        Button {
                            store.query = ""
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(category.tint)
                                    .frame(width: 8, height: 8)
                                Text(category.title)
                                    .font(LeoFont.body(12))
                                    .foregroundStyle(.white.opacity(0.92))
                                Spacer()
                                Text("\(apps.count)")
                                    .font(LeoFont.body(10))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(category.tint.opacity(0.16), in: Capsule())
                            .overlay(Capsule().strokeBorder(category.tint.opacity(0.28), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .dropDestination(for: String.self) { items, _ in
                            drop(items, onto: category)
                        }
                    }
                }
            }

            Spacer(minLength: 8)
            Text("⌥ Space 呼出")
                .font(LeoFont.body(10))
                .foregroundStyle(.white.opacity(0.4))
            Text(store.iCloudAvailable ? "iCloud 已同步" : "仅本机")
                .font(LeoFont.body(10))
                .foregroundStyle(store.iCloudAvailable ? Color.green.opacity(0.8) : .white.opacity(0.35))
        }
        .padding(12)
        .leoGlass(cornerRadius: 20)
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

struct RecentsRow: View {
    var apps: [AppRecord]
    var store: LauncherStore
    @Binding var hoveredID: String?
    var onLaunch: (AppRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.white.opacity(0.55))
                Text("最近")
                    .font(LeoFont.title(13))
                    .foregroundStyle(.white.opacity(0.72))
            }
            HStack(spacing: 10) {
                ForEach(apps) { app in
                    AppTile(
                        app: app,
                        size: store.iconSize,
                        hideName: true,
                        selected: store.selectedID == app.id,
                        hovered: hoveredID == app.id,
                        onLaunch: { onLaunch(app) },
                        onHover: { hoveredID = $0 ? app.id : nil }
                    )
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .leoGlass(cornerRadius: 18)
    }
}

struct ZoneCard: View {
    var zone: PackedZone
    var store: LauncherStore
    @Binding var hoveredID: String?
    var highlighted: Bool
    var onLaunch: (AppRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Capsule()
                    .fill(zone.category.tint)
                    .frame(width: 18, height: 4)
                Text(zone.category.title)
                    .font(LeoFont.title(13))
                    .foregroundStyle(.white.opacity(0.9))
                Text("\(zone.apps.count)")
                    .font(LeoFont.body(11))
                    .foregroundStyle(.white.opacity(0.38))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)

            FlexibleIconGrid(
                apps: zone.apps,
                iconSize: store.iconSize,
                hideNames: store.hideAppNames,
                selectedID: store.selectedID,
                hoveredID: hoveredID,
                onLaunch: onLaunch,
                onHover: { hoveredID = $0 }
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(zone.category.tint.opacity(highlighted ? 0.16 : 0.07))
        }
        .leoGlass(cornerRadius: 22)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(zone.category.tint.opacity(highlighted ? 0.7 : 0.22), lineWidth: highlighted ? 1.5 : 1)
        }
        .animation(.easeOut(duration: 0.12), value: highlighted)
    }
}

struct FlexibleIconGrid: View {
    var apps: [AppRecord]
    var iconSize: CGFloat
    var hideNames: Bool
    var selectedID: String?
    var hoveredID: String?
    var onLaunch: (AppRecord) -> Void
    var onHover: (String?) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: iconSize + (hideNames ? 10 : 18)), spacing: 8)],
            alignment: .leading,
            spacing: 8
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
            VStack(spacing: 4) {
                Image(nsImage: IconCache.shared.image(for: app.url, pointSize: size))
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(hovered || selected ? 0.35 : 0.18), radius: hovered ? 10 : 6, y: 3)
                    .scaleEffect(hovered || selected ? 1.08 : 1)
                if !hideName {
                    Text(app.name)
                        .font(LeoFont.body(10))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(1)
                        .frame(width: size + 16)
                }
            }
            .padding(6)
            .background {
                if selected || hovered {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.10))
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
