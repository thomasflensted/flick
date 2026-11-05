import AppKit
import SwiftUI

final class SettingsWindow {
    private var window: NSWindow?

    func show(library: Library, ai: AISettings, onImport: @escaping () -> Void) {
        library.reloadIfChanged()
        let window = window ?? makeWindow(library: library, ai: ai, onImport: onImport)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow(library: Library, ai: AISettings, onImport: @escaping () -> Void) -> NSWindow {
        let content = TabView {
            QuicklinksView(store: library.quicklinks, onImport: onImport).tabItem { Text("Quicklinks") }
            SnippetsView(store: library.snippets).tabItem { Text("Snippets") }
            AISettingsView(settings: ai).tabItem { Text("AI") }
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
