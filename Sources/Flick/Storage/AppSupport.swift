import Foundation

enum AppSupport {
    static let directory: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Flick", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let quicklinksFile = directory.appending(path: "quicklinks.json")
    static let snippetsFile = directory.appending(path: "snippets.json")
    static let clipboardFile = directory.appending(path: "clipboard.json")
    static let usageFile = directory.appending(path: "usage.json")
}
