import Foundation

public struct FoundFile: Hashable {
    public let url: URL

    public init(path: String) {
        url = URL(fileURLWithPath: path)
    }

    public var name: String { url.lastPathComponent }

    public func details(home: String = NSHomeDirectory()) -> String {
        let folder = url.deletingLastPathComponent().path
        return folder.hasPrefix(home) ? "~" + folder.dropFirst(home.count) : folder
    }
}

public enum FileResults {
    static let limit = 50

    public static func results(for query: String, in files: [FoundFile]) -> [ResultItem] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [.hint("Type to search files and folders")] }
        return Ranker(usage: [:]).rank(files, query: query, texts: { [$0.name] }, key: ResultItem.fileID).prefix(limit).map { .file($0) }
    }
}
