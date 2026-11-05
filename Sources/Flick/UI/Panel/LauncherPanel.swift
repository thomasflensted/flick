import AppKit

final class LauncherPanel: NSPanel {
    var onResignKey: () -> Void = {}

    init(content: NSView) {
        super.init(contentRect: content.frame, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        contentView = content
    }

    // Borderless panels can't become key by default, and the search field needs key status to take input.
    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        onResignKey()
    }
}
