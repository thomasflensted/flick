import Foundation

struct JSONFile<Value: Codable> {
    let url: URL

    var exists: Bool { FileManager.default.fileExists(atPath: url.path) }

    var modificationDate: Date? {
        // URL caches resource values, so drop the cache to see edits made by other processes.
        var fresh = url
        fresh.removeAllCachedResourceValues()
        return try? fresh.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    func load() throws -> Value {
        try JSONDecoder().decode(Value.self, from: Data(contentsOf: url))
    }

    func save(_ value: Value) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
