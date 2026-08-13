import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (filename, size) in sizes {
    let pixels = Int(size)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Unable to create bitmap for \(filename)")
    }
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("Unable to create context for \(filename)")
    }
    context.imageInterpolation = .high
    context.shouldAntialias = true
    NSGraphicsContext.current = context
    drawIcon(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode \(filename)")
    }
    try png.write(to: outputDirectory.appendingPathComponent(filename))
}

private func ink(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
}

func drawIcon(in rect: NSRect) {
    let size = rect.width
    let inset = size * 0.08
    let card = rect.insetBy(dx: inset, dy: inset)
    let radius = size * 0.215

    let shadow = NSBezierPath(roundedRect: card.offsetBy(dx: 0, dy: -size * 0.012), xRadius: radius, yRadius: radius)
    NSColor.black.withAlphaComponent(0.35).setFill()
    shadow.fill()

    let body = NSBezierPath(roundedRect: card, xRadius: radius, yRadius: radius)
    ink(0.09, 0.08, 0.07).setFill()
    body.fill()

    NSGradient(
        colors: [
            ink(0.22, 0.18, 0.14),
            ink(0.08, 0.07, 0.06)
        ]
    )?.draw(in: body, angle: 90)

    let highlight = NSBezierPath(
        roundedRect: card.insetBy(dx: size * 0.012, dy: size * 0.012),
        xRadius: radius * 0.9,
        yRadius: radius * 0.9
    )
    NSGradient(
        colors: [
            NSColor.white.withAlphaComponent(0.16),
            NSColor.white.withAlphaComponent(0)
        ]
    )?.draw(in: highlight, angle: 90)

    ink(0.82, 0.58, 0.34, 0.55).setStroke()
    body.lineWidth = max(1, size * 0.018)
    body.stroke()

    drawAppTiles(in: card, size: size)
}

struct AppTile {
    let scale: CGFloat
    let fill: NSColor
    let accent: NSColor
}

func drawAppTiles(in card: NSRect, size: CGFloat) {
    let compact = size <= 32
    let pad = compact ? size * 0.145 : size * 0.168
    let inner = card.insetBy(dx: pad, dy: pad)
    let gap = compact ? max(1.2, size * 0.07) : size * 0.058
    let cellW = (inner.width - gap) / 2
    let cellH = (inner.height - gap) / 2

    // 2×2 Launchpad-style tiles. Scales are mixed, not ranked, so it cannot read as a chart.
    let tiles: [AppTile] = [
        AppTile(scale: compact ? 1.00 : 1.00, fill: ink(0.86, 0.64, 0.40), accent: ink(0.97, 0.88, 0.70)),
        AppTile(scale: compact ? 0.92 : 0.86, fill: ink(0.93, 0.90, 0.84), accent: ink(1.00, 0.98, 0.94)),
        AppTile(scale: compact ? 0.94 : 0.90, fill: ink(0.62, 0.46, 0.32), accent: ink(0.82, 0.66, 0.48)),
        AppTile(scale: compact ? 0.98 : 0.96, fill: ink(0.78, 0.52, 0.30), accent: ink(0.94, 0.76, 0.52))
    ]

    for row in 0..<2 {
        for col in 0..<2 {
            let index = row * 2 + col
            let tile = tiles[index]
            let cell = NSRect(
                x: inner.minX + CGFloat(col) * (cellW + gap),
                y: inner.maxY - CGFloat(row + 1) * cellH - CGFloat(row) * gap,
                width: cellW,
                height: cellH
            )
            let side = min(cell.width, cell.height) * tile.scale
            let tileRect = NSRect(
                x: cell.midX - side / 2,
                y: cell.midY - side / 2,
                width: side,
                height: side
            )
            drawTile(tileRect, tile: tile, canvasSize: size)
        }
    }
}

func drawTile(_ rect: NSRect, tile: AppTile, canvasSize: CGFloat) {
    let radius = rect.width * 0.26

    if canvasSize >= 64 {
        let drop = NSBezierPath(
            roundedRect: rect.offsetBy(dx: 0, dy: -canvasSize * 0.006),
            xRadius: radius,
            yRadius: radius
        )
        NSColor.black.withAlphaComponent(0.28).setFill()
        drop.fill()
    }

    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    tile.fill.setFill()
    path.fill()

    if canvasSize >= 32 {
        NSGradient(
            colors: [
                tile.accent.withAlphaComponent(0.55),
                tile.fill.withAlphaComponent(0)
            ]
        )?.draw(in: path, angle: 90)

        NSColor.white.withAlphaComponent(0.22).setStroke()
        path.lineWidth = max(0.5, canvasSize * 0.006)
        path.stroke()
    }

    guard canvasSize >= 128 else { return }

    let face = rect.insetBy(dx: rect.width * 0.22, dy: rect.height * 0.22)
    let faceRadius = face.width * 0.28
    let facePath = NSBezierPath(roundedRect: face, xRadius: faceRadius, yRadius: faceRadius)
    tile.accent.withAlphaComponent(0.28).setFill()
    facePath.fill()
}
