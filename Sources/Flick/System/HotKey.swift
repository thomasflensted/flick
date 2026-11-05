import Carbon

final class HotKey {
    private static var nextID: UInt32 = 1
    private static let signature = OSType(0x464C_434B)

    private let id: UInt32
    private let action: () -> Void
    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?

    init?(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        id = Self.nextID
        Self.nextID += 1
        self.action = action
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }
            return Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue().handle(event)
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)
        let status = RegisterEventHotKey(keyCode, modifiers, EventHotKeyID(signature: Self.signature, id: id),
                                         GetApplicationEventTarget(), 0, &ref)
        if status != noErr { return nil }
    }

    deinit {
        if let ref { UnregisterEventHotKey(ref) }
        if let handler { RemoveEventHandler(handler) }
    }

    private func handle(_ event: EventRef) -> OSStatus {
        var pressed = EventHotKeyID()
        GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                          nil, MemoryLayout<EventHotKeyID>.size, nil, &pressed)
        guard pressed.id == id else { return OSStatus(eventNotHandledErr) }
        DispatchQueue.main.async(execute: action)
        return noErr
    }
}
