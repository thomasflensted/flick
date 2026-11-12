import Foundation

public struct FoundFile: Hashable {
    public let name: String
    public let url: URL

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }

    public func details(home: String = NSHomeDirectory()) -> String {
        let folder = url.deletingLastPathComponent().path
        return folder.hasPrefix(home) ? "~" + folder.dropFirst(home.count) : folder
    }
}

public enum FileResults {
    public static func results(for query: String, in files: [FoundFile]) -> [ResultItem] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [.hint("Type to search files and folders")] }
        return Ranker(usage: [:]).rank(files, query: query, texts: { [$0.name] }, key: ResultItem.fileID).map { .file($0) }
    }
}
