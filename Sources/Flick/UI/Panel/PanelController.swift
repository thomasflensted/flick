import AppKit
import Carbon
import FlickCore
import SwiftUI

final class PanelController {
    static let size = NSSize(width: 700, height: 460)

    private let model: SearchModel
    private let panel: LauncherPanel
    private let onOpenManager: () -> Void

    init(model: SearchModel, onOpenManager: @escaping () -> Void) {
        self.model = model
        self.onOpenManager = onOpenManager
        let host = NSHostingView(rootView: SearchView(model: model))
        host.frame = NSRect(origin: .zero, size: Self.size)
        panel = LauncherPanel(content: host)
        panel.onResignKey = { [weak self] in self?.hide() }
        model.onDone = { [weak self] in self?.hide() }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel.isKeyWindow, self.handle(event) else { return event }
            return nil
        }
    }

    func toggle(_ mode: Mode = .root) {
        panel.isVisible && model.mode == mode ? hide() : show(mode)
    }

    func show(_ mode: Mode = .root) {
        model.prepareForShow(in: mode)
        panel.setFrameOrigin(origin(on: screenUnderMouse()))
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func screenUnderMouse() -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
    }

    private func origin(on screen: NSScreen?) -> NSPoint {
        guard let frame = screen?.visibleFrame else { return .zero }
        return NSPoint(x: frame.midX - Self.size.width / 2, y: frame.maxY - frame.height * 0.18 - Self.size.height)
    }

    private func handle(_ event: NSEvent) -> Bool {
        switch Int(event.keyCode) {
        case kVK_DownArrow: model.move(.down)
        case kVK_UpArrow: model.move(.up)
        case kVK_LeftArrow where model.movesInGrid: model.move(.left)
        case kVK_RightArrow where model.movesInGrid: model.move(.right)
        case kVK_Return, kVK_ANSI_KeypadEnter:
            model.activate(delivery: event.modifierFlags.contains(.command) ? .copy : .paste)
        case kVK_Tab: model.tab()
        case kVK_Escape: if !model.escape() { hide() }
        case kVK_Delete: return model.deleteBackwardWhenEmpty()
        case kVK_ANSI_Comma where event.modifierFlags.contains(.command):
            hide()
            onOpenManager()
        default: return false
        }
        return true
    }
}
