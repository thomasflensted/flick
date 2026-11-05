public enum SnippetExpansion {
    public static func match(in typed: String, snippets: [Snippet]) -> Snippet? {
        snippets
            .filter { snippet in snippet.keyword.map { endsWithWord($0, in: typed) } ?? false }
            .max { ($0.keyword?.count ?? 0) < ($1.keyword?.count ?? 0) }
    }

    static func endsWithWord(_ keyword: String, in typed: String) -> Bool {
        guard typed.hasSuffix(keyword) else { return false }
        let before = typed.dropLast(keyword.count).last
        return before.map(\.isWhitespace) ?? true
    }
}
