import AppKit
import SwiftUI

final class ManagerWindow {
    private var window: NSWindow?

    func show(store: QuicklinkStore, onImport: @escaping () -> Void) {
        store.reloadIfChanged()
        let window = window ?? makeWindow(store: store, onImport: onImport)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow(store: QuicklinkStore, onImport: @escaping () -> Void) -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: QuicklinksView(store: store, onImport: onImport)))
        window.title = "Flick Quicklinks"
        window.setContentSize(NSSize(width: 820, height: 520))
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
