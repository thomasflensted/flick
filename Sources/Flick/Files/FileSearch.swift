import FlickCore
import Foundation

final class FileSearch {
    var onUpdate: () -> Void = {}
    private(set) var files: [FoundFile] = []
    private var latest = ""

    private static let home = URL(fileURLWithPath: NSHomeDirectory())
    private static let searchedFolders = ["Desktop", "Documents", "Downloads"].map { home.appendingPathComponent($0) }

    func requestAccess() {
        Background.load({ Self.searchedFolders.forEach { _ = try? FileManager.default.contentsOfDirectory(atPath: $0.path) } }) { _ in }
    }

    func search(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespaces)
        latest = text
        guard !text.isEmpty else { files = []; return }
        Background.load({ Self.homeFolders() + Self.paths(named: text) }) { [weak self] paths in
            guard let self, latest == text else { return }
            files = paths.map(FoundFile.init(path:))
            onUpdate()
        }
    }

    func clear() {
        latest = ""
        files = []
    }

    private static func homeFolders() -> [String] {
        let urls = try? FileManager.default.contentsOfDirectory(at: home, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        return (urls ?? []).map(\.path)
    }

    private static func paths(named text: String) -> [String] {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        process.arguments = ["-name", text] + searchedFolders.flatMap { ["-onlyin", $0.path] }
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return [] }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self).split(separator: "\n").map(String.init)
    }
}
