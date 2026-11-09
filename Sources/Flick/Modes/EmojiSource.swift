import FlickCore

final class EmojiSource: ModeSource {
    var onUpdate: () -> Void = {}
    private let usage: UsageStore

    init(usage: UsageStore) {
        self.usage = usage
    }

    func results(for query: String) -> [ResultItem] {
        EmojiCatalog.results(for: query, usage: usage.counts)
    }
}
