public enum SnippetSearch {
    public static func results(for query: String, snippets: [Snippet], usage: [String: Int]) -> [ResultItem] {
        Ranker(usage: usage)
            .rank(snippets, query: query, texts: { [$0.name, $0.keyword].compactMap { $0 } }, key: UsageKey.snippet)
            .map(ResultItem.snippet)
    }
}
