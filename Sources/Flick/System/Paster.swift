import AppKit
import ApplicationServices
import Carbon
import FlickCore

enum Paster {
    private static let delayForPanelToClose = 0.12

    static func deliver(_ text: String, _ delivery: Delivery) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        guard delivery == .paste, isTrusted() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delayForPanelToClose, execute: pressCommandV)
    }

    private static func pressCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        for keyDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: keyDown)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
        }
    }

    // The options dictionary is built with CFDictionaryCreate to avoid a bridging cast.
    private static func isTrusted() -> Bool {
        guard let yes = kCFBooleanTrue else { return AXIsProcessTrusted() }
        var keys: [UnsafeRawPointer?] = [UnsafeRawPointer(Unmanaged.passUnretained(kAXTrustedCheckOptionPrompt.takeUnretainedValue()).toOpaque())]
        var values: [UnsafeRawPointer?] = [UnsafeRawPointer(Unmanaged.passUnretained(yes).toOpaque())]
        let options = CFDictionaryCreate(nil, &keys, &values, 1, nil, nil)
        return AXIsProcessTrustedWithOptions(options)
    }
}
