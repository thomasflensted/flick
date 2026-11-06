import AppKit

final class StatusMenu {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    init(onShow: @escaping () -> Void, onSettings: @escaping () -> Void, onImport: @escaping () -> Void) {
        showKeepingAwake(false)
        let menu = NSMenu()
        menu.addItem(ActionMenuItem(title: "Open Flick", action: onShow))
        menu.addItem(ActionMenuItem(title: "Settings…", key: ",", action: onSettings))
        menu.addItem(ActionMenuItem(title: "Import from Raycast…", action: onImport))
        menu.addItem(.separator())
        menu.addItem(loginItem())
        menu.addItem(.separator())
        menu.addItem(ActionMenuItem(title: "Quit Flick", key: "q") { NSApp.terminate(nil) })
        item.menu = menu
    }

    func showKeepingAwake(_ active: Bool) {
        let symbol = active ? "sun.max.fill" : "command"
        let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        item.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: active ? "Flick (keeping awake)" : "Flick")?
            .withSymbolConfiguration(configuration)
    }

    private func loginItem() -> NSMenuItem {
        let menuItem = ActionMenuItem(title: "Launch at Login") {}
        menuItem.state = LoginItem.isEnabled ? .on : .off
        menuItem.handler = { [weak menuItem] in
            LoginItem.toggle()
            menuItem?.state = LoginItem.isEnabled ? .on : .off
        }
        return menuItem
    }
}

final class ActionMenuItem: NSMenuItem {
    var handler: () -> Void

    init(title: String, key: String = "", action: @escaping () -> Void) {
        handler = action
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        target = self
    }

    required init(coder: NSCoder) { fatalError("Not used") }

    @objc private func fire() { handler() }
}
