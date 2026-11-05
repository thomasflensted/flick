import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = QuicklinkStore()
    private let usage = UsageStore()
    private let manager = ManagerWindow()
    private lazy var model = SearchModel(store: store, usage: usage)
    private lazy var panel = PanelController(model: model, onOpenManager: { [weak self] in self?.showManager() })
    private var hotKey: HotKey?
    private var statusMenu: StatusMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusMenu = StatusMenu(
            onShow: { [weak self] in self?.panel.show() },
            onManage: { [weak self] in self?.showManager() },
            onImport: { [weak self] in self?.importFromRaycast() })
        registerHotKey()
    }

    private func registerHotKey() {
        hotKey = HotKey(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey)) { [weak self] in self?.panel.toggle() }
        guard hotKey == nil else { return }
        let alert = NSAlert()
        alert.messageText = "Couldn't register ⌘Space"
        alert.informativeText = "Another app (Raycast or Spotlight) is using ⌘Space. Quit it or change its shortcut, then relaunch Flick."
        alert.runModal()
    }

    private func showManager() {
        manager.show(store: store, onImport: { [weak self] in self?.importFromRaycast() })
    }

    private func importFromRaycast() {
        if RaycastImportFlow.run(into: store) { showManager() }
    }
}
