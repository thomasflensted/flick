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

    // AXFullScreen has no public constant, and pressing the full screen button reports success but does nothing.
    private static let fullScreenAttribute = "AXFullScreen" as CFString

    static func toggleFullScreen() {
        guard Accessibility.isTrusted(), let window = focusedWindow() else { return }
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue(window, fullScreenAttribute, &value)
        let isFullScreen = value.map { CFEqual($0, kCFBooleanTrue) } ?? false
        AXUIElementSetAttributeValue(window, fullScreenAttribute, isFullScreen ? kCFBooleanFalse : kCFBooleanTrue)
    }

    private static func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return element(kAXFocusedWindowAttribute, of: AXUIElementCreateApplication(app.processIdentifier))
    }

    // The Accessibility API hands back an untyped CFTypeRef, so the element has to be cast after checking its type.
    private static func element(_ attribute: String, of parent: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(parent, attribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    private static func set(_ attribute: String, _ value: AXValue?, on window: AXUIElement) {
        guard let value else { return }
        AXUIElementSetAttributeValue(window, attribute as CFString, value)
    }
}
