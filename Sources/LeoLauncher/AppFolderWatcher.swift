import CoreServices
import Foundation

/// Watches Applications folders and coalesces bursts of copy events before notifying.
final class AppFolderWatcher: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.leo.leolauncher.folder-watch")
    private let debounce: TimeInterval
    private let handler: @Sendable () -> Void
    private var stream: FSEventStreamRef?
    private var debounceWork: DispatchWorkItem?

    init(debounce: TimeInterval = 1.2, handler: @escaping @Sendable () -> Void) {
        self.debounce = debounce
        self.handler = handler
    }

    func start(paths: [String]) {
        queue.async { [self] in
            self.stopLocked()
            let existing = paths.filter { path in
                var isDir: ObjCBool = false
                return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
            }
            guard !existing.isEmpty else { return }

            var context = FSEventStreamContext(
                version: 0,
                info: Unmanaged.passUnretained(self).toOpaque(),
                retain: nil,
                release: nil,
                copyDescription: nil
            )
            let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
                guard let info else { return }
                Unmanaged<AppFolderWatcher>.fromOpaque(info).takeUnretainedValue().noteChange()
            }
            let flags = UInt32(
                kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagIgnoreSelf
            )
            guard let created = FSEventStreamCreate(
                kCFAllocatorDefault,
                callback,
                &context,
                existing as CFArray,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                0.4,
                flags
            ) else { return }

            FSEventStreamSetDispatchQueue(created, self.queue)
            guard FSEventStreamStart(created) else {
                FSEventStreamInvalidate(created)
                FSEventStreamRelease(created)
                return
            }
            self.stream = created
        }
    }

    func stop() {
        queue.sync { stopLocked() }
    }

    private func noteChange() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.handler()
        }
        debounceWork = work
        queue.asyncAfter(deadline: .now() + debounce, execute: work)
    }

    private func stopLocked() {
        debounceWork?.cancel()
        debounceWork = nil
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    deinit {
        debounceWork?.cancel()
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
}
