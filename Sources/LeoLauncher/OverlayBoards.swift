import SwiftUI

struct ColorSpectrumBoard: View {
    var groups: [(LogoHue, [AppRecord])]
    var store: LauncherStore
    @Binding var hoveredID: String?
    @Binding var focused: String?
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
                                    onLaunch: onLaunch
                                )
                                .id(hue.rawValue)
                            }
                        }
                        .padding(.horizontal, 36)
                        .padding(.bottom, 24)
                    }
                }
                .onChange(of: focused) { _, id in
                    guard let id else { return }
                    withAnimation(.easeOut(duration: 0.18)) {
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
                .fill(hue.tint.opacity(0.16))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(hue.tint.opacity(0.38), lineWidth: 1)
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
    }
}

struct TimeLaneBoard: View {
    var groups: [(TimeLane, [AppRecord])]
    var store: LauncherStore
    @Binding var hoveredID: String?
    @Binding var focused: String?
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
                        VStack(spacing: 22) {
                            ForEach(groups, id: \.0) { lane, apps in
                                TimeLaneSection(
                                    lane: lane,
                                    apps: apps,
                                    store: store,
                                    hoveredID: $hoveredID,
                                    onLaunch: onLaunch
                                )
                                .id(lane.rawValue)
                            }
                        }
                        .padding(.horizontal, 36)
                        .padding(.bottom, 24)
                    }
                }
                .onChange(of: focused) { _, id in
                    guard let id else { return }
                    withAnimation(.easeOut(duration: 0.18)) {
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
    var onLaunch: (AppRecord) -> Void
    @Environment(\.overlayPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Circle()
                    .fill(lane.tint)
                    .frame(width: 8, height: 8)
                    .offset(y: -1)
                Text(lane.title)
                    .font(LeoFont.title(lane == .justNow ? 22 : 18))
                Text(lane.subtitle)
                    .font(LeoFont.mono(11))
                    .foregroundStyle(palette.mute)
                Spacer(minLength: 0)
                Text("\(apps.count)")
                    .font(LeoFont.mono(11))
                    .foregroundStyle(palette.mute)
            }

            IconFlow(
                apps: apps,
                iconSize: store.iconSize * lane.iconScale,
                hideNames: store.hideAppNames,
                selectedID: store.selectedID,
                hoveredID: hoveredID,
                onLaunch: onLaunch,
                onHover: { hoveredID = $0 }
            )
        }
        .padding(lane == .justNow ? 20 : 16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            ZStack {
                if palette.usesMaterial {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(lane.tint.opacity(lane == .justNow ? 0.16 : 0.08))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(lane.tint.opacity(0.32), lineWidth: 1)
        }
    }
}
