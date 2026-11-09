import FlickCore

final class SnippetsSource: ModeSource {
    var onUpdate: () -> Void = {}
    private let snippets: SnippetStore
    private let usage: UsageStore

    init(snippets: SnippetStore, usage: UsageStore) {
        self.snippets = snippets
        self.usage = usage
    }

    func results(for query: String) -> [ResultItem] {
        SnippetSearch.results(for: query, snippets: snippets.items, usage: usage.counts)
    }
}
