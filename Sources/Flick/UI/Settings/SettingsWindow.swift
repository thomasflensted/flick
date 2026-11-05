import AppKit
import SwiftUI

final class SettingsWindow {
    private var window: NSWindow?

    func show(library: Library, onImport: @escaping () -> Void) {
        library.reloadIfChanged()
        let window = window ?? makeWindow(library: library, onImport: onImport)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow(library: Library, onImport: @escaping () -> Void) -> NSWindow {
        let content = TabView {
            QuicklinksView(store: library.quicklinks, onImport: onImport).tabItem { Text("Quicklinks") }
            SnippetsView(store: library.snippets).tabItem { Text("Snippets") }
        }
        .padding(.top, 8)
        let window = NSWindow(contentViewController: NSHostingController(rootView: content))
        window.title = "Flick Settings"
        window.setContentSize(NSSize(width: 820, height: 540))
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
