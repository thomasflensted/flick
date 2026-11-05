import AppKit
import Carbon
import ServiceManagement
import SwiftUI

final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let store = QuicklinkStore()
    private lazy var model = SearchModel(store: store)
    private var panel: LauncherPanel!
    private var hotKey: HotKey?
    private var statusItem: NSStatusItem!
    private var managerWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildPanel()
        buildStatusItem()
        model.onDone = { [weak self] in self?.hide() }

        hotKey = HotKey(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey)) { [weak self] in self?.toggle() }
        if hotKey == nil {
            let a = NSAlert()
            a.messageText = "Couldn't register ⌘Space"
            a.informativeText = "Another app (Raycast or Spotlight) is using ⌘Space. Quit it or change its shortcut, then relaunch Flick."
            a.runModal()
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self, self.panel.isKeyWindow else { return e }
            let ctrl = e.modifierFlags.contains(.control)
            let cmd = e.modifierFlags.contains(.command)
            switch e.keyCode {
            case UInt16(kVK_DownArrow): self.model.move(1); return nil
            case UInt16(kVK_UpArrow): self.model.move(-1); return nil
            case UInt16(kVK_ANSI_N) where ctrl: self.model.move(1); return nil
            case UInt16(kVK_ANSI_P) where ctrl: self.model.move(-1); return nil
            case UInt16(kVK_Return), UInt16(kVK_ANSI_KeypadEnter): self.model.activate(); return nil
            case UInt16(kVK_Tab): self.model.tab(); return nil
            case UInt16(kVK_Escape):
                if self.model.argumentTarget != nil { self.model.exitArgument() }
                else if self.model.query.isEmpty { self.hide() } else { self.model.query = "" }
                return nil
            case UInt16(kVK_Delete) where self.model.argumentTarget != nil && self.model.argument.isEmpty:
                self.model.exitArgument()
                return nil
            case UInt16(kVK_ANSI_Comma) where cmd: self.hide(); self.showManager(); return nil
            default: return e
            }
        }
    }

    // MARK: Panel

    private func buildPanel() {
        panel = LauncherPanel(contentRect: NSRect(x: 0, y: 0, width: 700, height: 460),
                              styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
                              backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.delegate = self
        let host = NSHostingView(rootView: SearchView(model: model))
        host.frame = NSRect(x: 0, y: 0, width: 700, height: 460)
        panel.contentView = host
    }

    private func toggle() {
        panel.isVisible ? hide() : show()
    }

    private func show() {
        model.prepareForShow()
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        if let f = screen?.visibleFrame {
            let size = panel.frame.size
            panel.setFrameOrigin(NSPoint(x: f.midX - size.width / 2, y: f.maxY - f.height * 0.18 - size.height))
        }
        panel.makeKeyAndOrderFront(nil)
    }

    private func hide() {
        panel.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        if (notification.object as? NSWindow) === panel { hide() }
    }

    // MARK: Menu bar

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "command", accessibilityDescription: "Flick")
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Flick", action: #selector(menuShow), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Manage Quicklinks…", action: #selector(menuManager), keyEquivalent: ",").target = self
        menu.addItem(withTitle: "Import from Raycast…", action: #selector(menuImport), keyEquivalent: "").target = self
        menu.addItem(.separator())
        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin(_:)), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Flick", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc private func menuShow() { show() }
    @objc private func menuManager() { showManager() }
    @objc private func menuImport() { runImport() }

    @objc private func toggleLogin(_ item: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            NSAlert(error: error).runModal()
        }
        item.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    // MARK: Manager window

    private func showManager() {
        store.reloadIfChanged()
        if managerWindow == nil {
            let w = NSWindow(contentViewController: NSHostingController(
                rootView: QuicklinksView(store: store, onImport: { [weak self] in self?.runImport() })))
            w.title = "Flick Quicklinks"
            w.setContentSize(NSSize(width: 820, height: 520))
            w.isReleasedWhenClosed = false
            w.center()
            managerWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        managerWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: Import

    private func runImport() {
        NSApp.activate(ignoringOtherApps: true)
        let open = NSOpenPanel()
        open.title = "Choose your Raycast export (.rayconfig)"
        open.message = "In Raycast: Settings → Advanced → Export. Then pick the .rayconfig file here."
        open.allowsOtherFileTypes = true
        open.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        guard open.runModal() == .OK, let url = open.url else { return }

        var password: String? = nil
        while true {
            do {
                let links = try RaycastImporter.load(url: url, password: password)
                let added = store.merge(links)
                let a = NSAlert()
                a.messageText = "Imported \(added) quicklinks"
                a.informativeText = added < links.count ? "\(links.count - added) were already in Flick and were skipped." : ""
                a.runModal()
                showManager()
                return
            } catch RaycastImporter.ImportError.needsPassword {
                guard let pw = askPassword(message: "Enter the password you set when exporting from Raycast.") else { return }
                password = pw
            } catch RaycastImporter.ImportError.wrongPasswordOrFormat {
                guard let pw = askPassword(message: "That didn't work. Check the export password and try again.") else { return }
                password = pw
            } catch {
                NSAlert(error: error).runModal()
                return
            }
        }
    }

    private func askPassword(message: String) -> String? {
        let a = NSAlert()
        a.messageText = "Raycast export password"
        a.informativeText = message
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        a.accessoryView = field
        a.addButton(withTitle: "Import")
        a.addButton(withTitle: "Cancel")
        a.window.initialFirstResponder = field
        return a.runModal() == .alertFirstButtonReturn ? field.stringValue : nil
    }
}
