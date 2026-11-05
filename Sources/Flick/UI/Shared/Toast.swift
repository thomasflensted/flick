import AppKit
import FlickCore
import SwiftUI

final class Toast {
    static let shared = Toast()

    private static let visibleSeconds = 1.6
    private static let fadeSeconds = 0.2
    private static let distanceFromBottom: CGFloat = 140

    private let panel: NSPanel
    private var hideWork: DispatchWorkItem?

    private init() {
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func show(_ feedback: Feedback) {
        let host = NSHostingView(rootView: ToastView(feedback: feedback))
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        panel.contentView = host
        panel.setFrame(frame(for: host.fittingSize), display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        scheduleHide()
    }

    private func frame(for size: NSSize) -> NSRect {
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        return NSRect(x: visible.midX - size.width / 2, y: visible.minY + Self.distanceFromBottom, width: size.width, height: size.height)
    }

    private func scheduleHide() {
        hideWork?.cancel()
        let work = DispatchWorkItem { [panel] in
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = Self.fadeSeconds
                panel.animator().alphaValue = 0
            }, completionHandler: { panel.orderOut(nil) })
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.visibleSeconds, execute: work)
    }
}

private struct ToastView: View {
    let feedback: Feedback

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: feedback.symbol)
            Text(feedback.text)
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Capsule().fill(Color.black.opacity(0.78)))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12)))
        .padding(10)
    }
}
