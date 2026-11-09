import FlickCore
import Foundation

final class ClipboardSource: ModeSource {
    var onUpdate: () -> Void = {}
    private let clipboard: ClipboardStore

    init(clipboard: ClipboardStore) {
        self.clipboard = clipboard
    }

    func results(for query: String) -> [ResultItem] {
        ClipHistory.results(for: query, in: clipboard.entries, now: Date())
    }

    func remove(_ kind: ResultKind) {
        guard case .clip(let entry) = kind else { return }
        clipboard.delete(entry.id)
        onUpdate()
    }
}
