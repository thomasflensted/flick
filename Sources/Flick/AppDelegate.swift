import AppKit
import Carbon
import FlickCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let library = Library()
    private let usage = UsageStore()
    private let settings = SettingsWindow()
    private let commands = CommandRunner()
    private let ai = AISettings()
    private lazy var expander = SnippetExpander(store: library.snippets)
    private lazy var model = SearchModel(library: library, usage: usage, runner: ResultRunner(commands: commands),
                                         chat: ChatSession(settings: ai))
    private lazy var panel = PanelController(model: model, onOpenSettings: { [weak self] in self?.showSettings() })
    private var hotKeys: [HotKey] = []
    private var statusMenu: StatusMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusMenu = StatusMenu(
            onShow: { [weak self] in self?.panel.show() },
            onSettings: { [weak self] in self?.showSettings() },
            onImport: { [weak self] in self?.importFromRaycast() })
        commands.keepAwake.onChange = { [weak self] active in self?.statusMenu?.showKeepingAwake(active) }
        commands.keepAwake.onExpire = { Toast.shared.show(.sleepAllowed) }
        registerHotKeys()
        expander.start()
    }

    private func registerHotKeys() {
        let launcher = HotKey(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey)) { [weak self] in self?.panel.toggle() }
        let emoji = HotKey(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey | controlKey)) { [weak self] in self?.panel.toggle(.emoji) }
        hotKeys = [launcher, emoji].compactMap { $0 }
        guard launcher == nil else { return }
        let alert = NSAlert()
        alert.messageText = "Couldn't register ⌘Space"
        alert.informativeText = "Another app (Raycast or Spotlight) is using ⌘Space. Quit it or change its shortcut, then relaunch Flick."
        alert.runModal()
    }

    private func showSettings() {
        settings.show(library: library, ai: ai, onImport: { [weak self] in self?.importFromRaycast() })
    }

    private func importFromRaycast() {
        if RaycastImportFlow.run(into: library) { showSettings() }
    }
}
