import AppKit
import FlickCore

enum Launcher {
    static func open(_ ql: Quicklink, argument: String) {
        guard let url = URLText.url(from: ql.resolved(argument: argument)) else { return }
        if let app = appURL(for: ql.openWith) {
            NSWorkspace.shared.open([url], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    static func open(_ app: AppEntry) {
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: app.path), configuration: NSWorkspace.OpenConfiguration())
    }

    static func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    static func revealQuicklinksFile() {
        NSWorkspace.shared.activateFileViewerSelecting([AppSupport.quicklinksFile])
    }

    static func appURL(for openWith: String?) -> URL? {
        guard let openWith else { return nil }
        if URLText.isPath(openWith) { return URL(fileURLWithPath: URLText.expandingTilde(openWith)) }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: openWith)
    }
}
