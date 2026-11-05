import AppKit
import Carbon
import FlickCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let library = Library()
    private let usage = UsageStore()
    private let manager = ManagerWindow()
    private let commands = CommandRunner()
    private lazy var model = SearchModel(library: library, usage: usage, runner: ResultRunner(commands: commands))
    private lazy var panel = PanelController(model: model, onOpenManager: { [weak self] in self?.showManager() })
    private var hotKeys: [HotKey] = []
    private var statusMenu: StatusMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusMenu = StatusMenu(
            onShow: { [weak self] in self?.panel.show() },
            onManage: { [weak self] in self?.showManager() },
            onImport: { [weak self] in self?.importFromRaycast() })
        commands.keepAwake.onChange = { [weak self] active in self?.statusMenu?.showKeepingAwake(active) }
        commands.keepAwake.onExpire = { Toast.shared.show(.sleepAllowed) }
        registerHotKeys()
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

    private func showManager() {
        manager.show(library: library, onImport: { [weak self] in self?.importFromRaycast() })
    }

    private func importFromRaycast() {
        if RaycastImportFlow.run(into: library) { showManager() }
    }
}
