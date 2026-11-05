import AppKit

// Menu bar apps have no menus, and text fields only get ⌘C/⌘V/⌘X/⌘A/⌘Z through the Edit menu.
enum MainMenu {
    static func install() {
        let menu = NSMenu()
        menu.addItem(submenu(title: "Flick", items: [
            NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"),
        ]))
        menu.addItem(submenu(title: "Edit", items: [
            NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"),
            redo(),
            .separator(),
            NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
            NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
            NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
            NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"),
        ]))
        NSApp.mainMenu = menu
    }

    private static func redo() -> NSMenuItem {
        let item = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        item.keyEquivalentModifierMask = [.command, .shift]
        return item
    }

    private static func submenu(title: String, items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: title)
        items.forEach(submenu.addItem)
        item.submenu = submenu
        return item
    }
}
