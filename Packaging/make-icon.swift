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

func drawIcon(in rect: NSRect) {
    let size = rect.width
    let inset = size * 0.08
    let card = rect.insetBy(dx: inset, dy: inset)
    let radius = size * 0.215

    let shadow = NSBezierPath(roundedRect: card.offsetBy(dx: 0, dy: -size * 0.012), xRadius: radius, yRadius: radius)
    NSColor.black.withAlphaComponent(0.35).setFill()
    shadow.fill()

    let body = NSBezierPath(roundedRect: card, xRadius: radius, yRadius: radius)
    NSColor(calibratedRed: 0.09, green: 0.08, blue: 0.07, alpha: 1).setFill()
    body.fill()

    let gradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.22, green: 0.18, blue: 0.14, alpha: 1),
            NSColor(calibratedRed: 0.08, green: 0.07, blue: 0.06, alpha: 1)
        ]
    )
    gradient?.draw(in: body, angle: 90)

    let highlight = NSBezierPath(roundedRect: card.insetBy(dx: size * 0.012, dy: size * 0.012), xRadius: radius * 0.9, yRadius: radius * 0.9)
    NSGradient(
        colors: [
            NSColor.white.withAlphaComponent(0.16),
            NSColor.white.withAlphaComponent(0)
        ]
    )?.draw(in: highlight, angle: 90)

    NSColor(calibratedRed: 0.82, green: 0.58, blue: 0.34, alpha: 0.55).setStroke()
    body.lineWidth = max(1, size * 0.018)
    body.stroke()

    let inner = card.insetBy(dx: size * 0.18, dy: size * 0.20)
    let gap = inner.width * 0.12
    let barWidth = (inner.width - gap * 2) / 3
    let heights: [CGFloat] = [0.92, 0.68, 0.46]
    let colors: [NSColor] = [
        NSColor(calibratedRed: 0.86, green: 0.64, blue: 0.40, alpha: 1),
        NSColor(calibratedRed: 0.93, green: 0.90, blue: 0.84, alpha: 0.92),
        NSColor(calibratedRed: 0.72, green: 0.52, blue: 0.32, alpha: 0.88)
    ]

    for index in 0..<3 {
        let barHeight = inner.height * heights[index]
        let x = inner.minX + CGFloat(index) * (barWidth + gap)
        let y = inner.minY
        let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
        let bar = NSBezierPath(roundedRect: barRect, xRadius: barWidth / 2, yRadius: barWidth / 2)
        colors[index].setFill()
        bar.fill()
        NSColor.white.withAlphaComponent(0.18).setStroke()
        bar.lineWidth = max(0.5, size * 0.008)
        bar.stroke()
    }
}
