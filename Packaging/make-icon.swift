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
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    drawIcon(size: size)
    image.unlockFocus()

    guard let data = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: data),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to render \(filename)")
    }
    try png.write(to: outputDirectory.appendingPathComponent(filename))
}

func drawIcon(size: CGFloat) {
    let inset = size * 0.06
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = size * 0.22
    let background = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.14, alpha: 1).setFill()
    background.fill()

    let glow = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.04, dy: size * 0.04), xRadius: radius * 0.9, yRadius: radius * 0.9)
    NSColor(calibratedRed: 0.35, green: 0.72, blue: 0.98, alpha: 0.18).setFill()
    glow.fill()

    func tile(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, color: NSColor) {
        let r = NSRect(x: x, y: y, width: w, height: h)
        let path = NSBezierPath(roundedRect: r, xRadius: size * 0.06, yRadius: size * 0.06)
        color.setFill()
        path.fill()
        NSColor.white.withAlphaComponent(0.28).setStroke()
        path.lineWidth = max(1, size * 0.012)
        path.stroke()
    }

    let originX = size * 0.18
    let originY = size * 0.18
    let board = size * 0.64
    let gap = size * 0.045

    tile(originX, originY + board * 0.42 + gap, board * 0.58, board * 0.58,
         color: NSColor(calibratedRed: 0.45, green: 0.38, blue: 0.98, alpha: 0.92))
    tile(originX + board * 0.58 + gap, originY + board * 0.42 + gap, board * 0.42 - gap, board * 0.58,
         color: NSColor(calibratedRed: 0.20, green: 0.78, blue: 0.98, alpha: 0.92))
    tile(originX, originY, board, board * 0.42,
         color: NSColor(calibratedRed: 0.98, green: 0.58, blue: 0.28, alpha: 0.92))
}
