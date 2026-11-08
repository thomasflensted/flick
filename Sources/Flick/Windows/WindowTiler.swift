import AppKit
import ApplicationServices
import FlickCore

enum WindowTiler {
    static func tile(_ tile: WindowTile) {
        guard Accessibility.isTrusted(),
              let screen = NSScreen.underMouse,
              let primaryHeight = NSScreen.screens.first?.frame.height,
              let window = focusedWindow() else { return }
        let frame = tile.frame(in: screen.visibleFrame)
        var origin = WindowTile.topLeftOrigin(of: frame, primaryScreenHeight: primaryHeight)
        var size = frame.size
        set(kAXPositionAttribute, AXValueCreate(.cgPoint, &origin), on: window)
        set(kAXSizeAttribute, AXValueCreate(.cgSize, &size), on: window)
    }

    // The Accessibility API hands back an untyped CFTypeRef, so the window has to be cast after checking its type.
    private static func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        var value: CFTypeRef?
        let element = AXUIElementCreateApplication(app.processIdentifier)
        guard AXUIElementCopyAttributeValue(element, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    private static func set(_ attribute: String, _ value: AXValue?, on window: AXUIElement) {
        guard let value else { return }
        AXUIElementSetAttributeValue(window, attribute as CFString, value)
    }
}
