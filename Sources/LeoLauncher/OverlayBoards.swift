import SwiftUI

struct ColorSpectrumBoard: View {
    var groups: [(LogoHue, [AppRecord])]
    var store: LauncherStore
    @Binding var hoveredID: String?
    @Binding var focused: String?
    var jumpToken: Int
    var pulseSection: String?
    var onDismiss: () -> Void
    var onLaunch: (AppRecord) -> Void

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .top) {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: geo.size.height)
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onDismiss)
                        VStack(spacing: 12) {
                            ForEach(groups, id: \.0) { hue, apps in
                                ColorBand(
                                    hue: hue,
                                    apps: apps,
                                    store: store,
                                    hoveredID: $hoveredID,
                                    emphasized: pulseSection == hue.rawValue,
                                    onLaunch: onLaunch
                                )
                                .id(hue.rawValue)
                            }
                        }
                        .padding(.horizontal, 36)
                        .padding(.bottom, 24)
                    }
                }
                .onChange(of: jumpToken) {
                    guard let id = focused else { return }
                    withAnimation(.easeOut(duration: 0.22)) {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
    }
}

struct ColorBand: View {
    var hue: LogoHue
    var apps: [AppRecord]
    var store: LauncherStore
    @Binding var hoveredID: String?
    var emphasized: Bool
    var onLaunch: (AppRecord) -> Void
    @Environment(\.overlayPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(hue.tint)
                    .frame(width: 10, height: 10)
                    .shadow(color: hue.tint.opacity(0.7), radius: 6)
                Text(hue.title)
                    .font(LeoFont.title(18))
                    .foregroundStyle(hue.tint)
                Text("\(apps.count)")
                    .font(LeoFont.mono(11))
                    .foregroundStyle(palette.mute)
                Spacer(minLength: 0)
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
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(hue.tint.opacity(emphasized ? 0.28 : 0.16))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(hue.tint.opacity(emphasized ? 0.95 : 0.38), lineWidth: emphasized ? 1.8 : 1)
        }
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(
                topLeadingRadius: 14,
                bottomLeadingRadius: 14,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(hue.tint)
            .frame(width: 5)
        }
        .shadow(color: hue.tint.opacity(emphasized ? 0.5 : 0), radius: emphasized ? 18 : 0)
        .scaleEffect(emphasized ? 1.02 : 1)
        .animation(.spring(duration: 0.28, bounce: 0.18), value: emphasized)
    }
}

struct TimeLaneBoard: View {
    var groups: [(TimeLane, [AppRecord])]
    var store: LauncherStore
    @Binding var hoveredID: String?
    @Binding var focused: String?
    var jumpToken: Int
    var pulseSection: String?
    var onDismiss: () -> Void
    var onLaunch: (AppRecord) -> Void

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .top) {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: geo.size.height)
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onDismiss)
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(groups.enumerated()), id: \.element.0) { index, pair in
                                TimeLaneSection(
                                    lane: pair.0,
                                    apps: pair.1,
                                    store: store,
                                    hoveredID: $hoveredID,
                                    isLast: index == groups.count - 1,
                                    emphasized: pulseSection == pair.0.id,
                                    onLaunch: onLaunch
                                )
                                .id(pair.0.id)
                            }
                        }
                        .padding(.horizontal, 36)
                        .padding(.bottom, 24)
                    }
                }
                .onChange(of: jumpToken) {
                    guard let id = focused else { return }
                    withAnimation(.easeOut(duration: 0.22)) {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
    }
}

struct TimeLaneSection: View {
    var lane: TimeLane
    var apps: [AppRecord]
    var store: LauncherStore
    @Binding var hoveredID: String?
    var isLast: Bool
    var emphasized: Bool
    var onLaunch: (AppRecord) -> Void
    @Environment(\.overlayPalette) private var palette

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(lane.tint)
                    .frame(width: emphasized ? 13 : 11, height: emphasized ? 13 : 11)
                    .shadow(color: lane.tint.opacity(emphasized ? 0.9 : 0.65), radius: emphasized ? 10 : 6)
                    .overlay {
                        Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    }
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [lane.tint.opacity(0.55), palette.line],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 11)
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(lane.title)
                        .font(LeoFont.title(lane == .week ? 22 : 18))
                        .foregroundStyle(emphasized ? lane.tint : palette.text)
                    Text(InstallDate.range(apps) ?? lane.subtitle)
                        .font(LeoFont.mono(11))
                        .foregroundStyle(palette.mute)
                    Spacer(minLength: 0)
                    Text("\(apps.count)")
                        .font(LeoFont.mono(11))
                        .foregroundStyle(palette.mute)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: store.iconSize + 36), spacing: 10)],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(apps) { app in
                        TimeAppCell(
                            app: app,
                            size: store.iconSize,
                            selected: store.selectedID == app.id,
                            hovered: hoveredID == app.id,
                            onLaunch: { onLaunch(app) },
                            onHover: { hoveredID = $0 ? app.id : nil }
                        )
                    }
                }
                .padding(.bottom, isLast ? 8 : 28)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(emphasized ? 10 : 0)
        .background {
            if emphasized {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(lane.tint.opacity(0.14))
            }
        }
        .overlay {
            if emphasized {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(lane.tint.opacity(0.8), lineWidth: 1.4)
            }
        }
        .shadow(color: lane.tint.opacity(emphasized ? 0.4 : 0), radius: emphasized ? 16 : 0)
        .animation(.spring(duration: 0.28, bounce: 0.18), value: emphasized)
    }
}

struct TimeAppCell: View {
    var app: AppRecord
    var size: CGFloat
    var selected: Bool
    var hovered: Bool
    var onLaunch: () -> Void
    var onHover: (Bool) -> Void
    @Environment(\.overlayPalette) private var palette

    var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 5) {
                Image(nsImage: IconCache.shared.image(for: app.url, pointSize: size))
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size, height: size)
                    .scaleEffect(hovered || selected ? 1.06 : 1)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
                Text(app.name)
                    .font(LeoFont.body(10))
                    .foregroundStyle(palette.text.opacity(0.9))
                    .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                    .lineLimit(1)
                    .frame(width: size + 28)
                Text(InstallDate.caption(app.installedAt))
                    .font(LeoFont.mono(9))
                    .foregroundStyle(Ink.copper.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background {
                if selected || hovered {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Ink.copper.opacity(0.16))
                }
            }
        }
        .buttonStyle(.plain)
        .help("\(app.name) · \(InstallDate.caption(app.installedAt))")
        .onHover(perform: onHover)
        .animation(.easeOut(duration: 0.08), value: hovered)
        .contextMenu {
            Button("打开") { onLaunch() }
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
