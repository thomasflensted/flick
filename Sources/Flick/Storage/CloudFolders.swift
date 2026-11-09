import Foundation

enum CloudFolders {
    static func available() -> [String] {
        let library = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library", directoryHint: .isDirectory)
        let iCloudDrive = library.appending(path: "Mobile Documents/com~apple~CloudDocs", directoryHint: .isDirectory)
        let providers = (try? FileManager.default.contentsOfDirectory(at: library.appending(path: "CloudStorage"), includingPropertiesForKeys: nil)) ?? []
        return ([iCloudDrive] + providers).filter(isDirectory).map(\.path)
    }

    private static func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
