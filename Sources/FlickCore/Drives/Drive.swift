import Foundation

public struct Drive: Hashable {
    public let name: String
    public let url: URL
    public let capacity: Int64?

    public init(name: String, url: URL, capacity: Int64?) {
        self.name = name
        self.url = url
        self.capacity = capacity
    }

    public static func canEject(isRoot: Bool, isEjectable: Bool, isRemovable: Bool, isLocal: Bool) -> Bool {
        !isRoot && (isEjectable || isRemovable || !isLocal)
    }

    var details: String {
        let size = capacity.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) }
        return [url.path, size].compactMap { $0 }.joined(separator: " · ")
    }
}

public enum Drives {
    public static func results(for query: String, in drives: [Drive]) -> [ResultItem] {
        if drives.isEmpty { return [.hint("No drives to eject")] }
        return Ranker(usage: [:]).rank(drives, query: query, texts: { [$0.name] }, key: ResultItem.driveID).map(ResultItem.drive)
    }
}
