import AppKit
import ApplicationServices
import Carbon
import FlickCore

enum Paster {
    private static let delayForPanelToClose = 0.12
    private static let delayBeforeRestoringClipboard = 0.4
    private static let syntheticMarker: Int64 = 0x464C_434B
    private static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    @discardableResult
    static func deliver(_ text: String, _ delivery: Delivery) -> Delivery {
        setClipboard(text)
        guard delivery == .paste, isTrusted() else { return .copy }
        DispatchQueue.main.asyncAfter(deadline: .now() + delayForPanelToClose) { press(kVK_ANSI_V, flags: .maskCommand) }
        return .paste
    }

    static func replaceTyped(characters count: Int, with text: String) {
        guard isTrusted() else { return }
        let saved = savedClipboard()
        setClipboard(text, transient: true)
        for _ in 0..<count { press(kVK_Delete) }
        press(kVK_ANSI_V, flags: .maskCommand)
        DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeRestoringClipboard) { restoreClipboard(saved) }
    }

    static func isSynthetic(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == syntheticMarker
    }

    private static func setClipboard(_ text: String, transient: Bool = false) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        if transient { NSPasteboard.general.setData(Data(), forType: transientType) }
    }

    private static func savedClipboard() -> [NSPasteboardItem] {
        (NSPasteboard.general.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) { copy.setData(data, forType: type) }
            }
            return copy
        }
    }

    private static func restoreClipboard(_ items: [NSPasteboardItem]) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(items)
        NSPasteboard.general.setData(Data(), forType: transientType)
    }

    private static func press(_ key: Int, flags: CGEventFlags = []) {
        let source = CGEventSource(stateID: .combinedSessionState)
        for keyDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key), keyDown: keyDown)
            event?.flags = flags
            event?.setIntegerValueField(.eventSourceUserData, value: syntheticMarker)
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
