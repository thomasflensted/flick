import Foundation

enum AppSupport {
    private static let syncFolderKey = "syncFolder"

    static let directory: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Flick", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static var syncFolder: String? {
        get { UserDefaults.standard.string(forKey: syncFolderKey) }
        set { UserDefaults.standard.set(newValue, forKey: syncFolderKey) }
    }

    static var syncedDirectory: URL {
        syncFolder.map { URL(fileURLWithPath: $0, isDirectory: true) } ?? directory
    }

    static var quicklinksFile: URL { syncedDirectory.appending(path: "quicklinks.json") }
    static var snippetsFile: URL { syncedDirectory.appending(path: "snippets.json") }
    static let clipboardFile = directory.appending(path: "clipboard.json")
    static let ratesFile = directory.appending(path: "rates.json")
    static let usageFile = directory.appending(path: "usage.json")
}
