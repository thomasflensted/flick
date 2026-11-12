import FlickCore
import Foundation

final class FileSearch {
    var onUpdate: () -> Void = {}
    private(set) var files: [FoundFile] = []
    private let query = NSMetadataQuery()

    private static let limit = 50

    init() {
        query.searchScopes = [NSMetadataQueryUserHomeScope]
        query.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemLastUsedDateKey, ascending: false)]
        NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: query, queue: .main) { [weak self] _ in
            self?.gathered()
        }
    }

    func search(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespaces)
        query.stop()
        guard !text.isEmpty else { files = []; return }
        query.predicate = NSPredicate(format: "%K CONTAINS[cd] %@", NSMetadataItemFSNameKey, text)
        query.start()
    }

    func clear() {
        query.stop()
        files = []
    }

    private func gathered() {
        query.stop()
        files = query.results.prefix(Self.limit).compactMap(Self.file)
        onUpdate()
    }

    private static func file(_ result: Any) -> FoundFile? {
        guard let item = result as? NSMetadataItem, let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else { return nil }
        return FoundFile(name: FileManager.default.displayName(atPath: path), url: URL(fileURLWithPath: path))
    }
}
