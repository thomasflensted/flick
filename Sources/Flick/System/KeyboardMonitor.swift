import AppKit
import Carbon

enum TypingEvent {
    case typed(String)
    case deleteBackward
    case interrupted
}

final class KeyboardMonitor {
    private static let retrySeconds = 5.0
    private static let watchedEvents: [CGEventType] = [.keyDown, .leftMouseDown, .rightMouseDown]

    private let onEvent: (TypingEvent) -> Void
    private var tap: CFMachPort?
    private var retry: Timer?

    init(onEvent: @escaping (TypingEvent) -> Void) {
        self.onEvent = onEvent
    }

    func start() {
        if !CGPreflightListenEventAccess() { CGRequestListenEventAccess() }
        if installTap() { return }
        retry = Timer.scheduledTimer(withTimeInterval: Self.retrySeconds, repeats: true) { [weak self] timer in
            if self?.installTap() ?? true { timer.invalidate() }
        }
    }

    private func installTap() -> Bool {
        let mask = Self.watchedEvents.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .tailAppendEventTap, options: .listenOnly,
                                          eventsOfInterest: mask, callback: { _, type, event, userInfo in
            if let userInfo { Unmanaged<KeyboardMonitor>.fromOpaque(userInfo).takeUnretainedValue().handle(type, event) }
            return Unmanaged.passUnretained(event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return false }
        self.tap = tap
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
        return true
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        case .keyDown:
            guard !Paster.isSynthetic(event) else { return }
            onEvent(typingEvent(for: event))
        default:
            onEvent(.interrupted)
        }
    }

    private func typingEvent(for event: CGEvent) -> TypingEvent {
        if event.flags.contains(.maskCommand) || event.flags.contains(.maskControl) { return .interrupted }
        switch Int(event.getIntegerValueField(.keyboardEventKeycode)) {
        case kVK_Delete: return .deleteBackward
        case kVK_Return, kVK_ANSI_KeypadEnter, kVK_Tab: return .typed(" ")
        case kVK_LeftArrow, kVK_RightArrow, kVK_UpArrow, kVK_DownArrow, kVK_Escape: return .interrupted
        default: return NSEvent(cgEvent: event)?.characters.map(TypingEvent.typed) ?? .interrupted
        }
    }
}
