import AppKit
import Foundation

final class IconCache: @unchecked Sendable {
    static let shared = IconCache()

    private let memory = NSCache<NSString, NSImage>()
    private let queue = DispatchQueue(label: "com.leo.leolauncher.icons", qos: .userInitiated, attributes: .concurrent)
    private let diskRoot: URL

    private init() {
        memory.countLimit = 400
        let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LeoLauncher/Icons", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        diskRoot = root
    }

    func image(for url: URL, pointSize: CGFloat) -> NSImage {
        let key = cacheKey(url: url, pointSize: pointSize)
        if let hit = memory.object(forKey: key as NSString) {
            return hit
        }
        if let disk = NSImage(contentsOf: diskURL(key: key)) {
            memory.setObject(disk, forKey: key as NSString)
            return disk
        }
        let generated = render(url: url, pointSize: pointSize)
        memory.setObject(generated, forKey: key as NSString)
        queue.async { [diskRoot] in
            Self.persist(generated, to: diskRoot.appendingPathComponent(key))
        }
        return generated
    }

    func prefetch(urls: [URL], pointSize: CGFloat) {
        queue.async { [weak self] in
            guard let self else { return }
            for url in urls {
                _ = self.image(for: url, pointSize: pointSize)
            }
        }
    }

    private func render(url: URL, pointSize: CGFloat) -> NSImage {
        let source = NSWorkspace.shared.icon(forFile: url.path)
        let pixels = max(32, Int(pointSize * 2))
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize))
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        source.draw(
            in: NSRect(x: 0, y: 0, width: pointSize, height: pointSize),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        image.unlockFocus()
        image.checkForRepresentation(matching: NSSize(width: pixels, height: pixels))
        return image
    }

    private func cacheKey(url: URL, pointSize: CGFloat) -> String {
        let stamp = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate?.timeIntervalSince1970) ?? 0
        return "\(url.path.hashValue)-\(Int(pointSize))-\(Int(stamp)).png"
    }

    private func diskURL(key: String) -> URL {
        diskRoot.appendingPathComponent(key)
    }

    private static func persist(_ image: NSImage, to url: URL) {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url)
    }
}

private extension NSImage {
    func checkForRepresentation(matching size: NSSize) {
        if representations.contains(where: { $0.pixelsWide >= Int(size.width) }) { return }
        guard let tiff = tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return }
        bitmap.size = size
        addRepresentation(bitmap)
    }
}
