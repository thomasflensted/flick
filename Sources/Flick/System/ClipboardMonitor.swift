import AppKit
import FlickCore

final class ClipboardMonitor {
    private static let pollSeconds = 0.5

    private let store: ClipboardStore
    private var lastChange = NSPasteboard.general.changeCount
    private var timer: Timer?

    init(store: ClipboardStore) {
        self.store = store
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollSeconds, repeats: true) { [weak self] _ in self?.check() }
    }

    private func check() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChange else { return }
        lastChange = pasteboard.changeCount
        let types = (pasteboard.types ?? []).map(\.rawValue)
        guard ClipHistory.shouldRecord(types: types), let text = pasteboard.string(forType: .string) else { return }
        let app = NSWorkspace.shared.frontmostApplication
        store.record(ClipEntry(text: text, copiedAt: Date(), appName: app?.localizedName, appPath: app?.bundleURL?.path))
    }
}
