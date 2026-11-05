public struct Ranker {
    public let usage: [String: Int]

    public init(usage: [String: Int]) {
        self.usage = usage
    }

    public func rank<T>(_ items: [T], query: String, text: (T) -> String, key: (T) -> String) -> [T] {
        let query = query.trimmingCharacters(in: .whitespaces)
        let scored = items.enumerated().compactMap { index, item in
            MatchScore.score(query, against: text(item)).map { (score: $0 + boost(key(item)), index: index, item: item) }
        }
        return scored.sorted { ($0.score, -$0.index) > ($1.score, -$1.index) }.map(\.item)
    }

    private func boost(_ key: String) -> Int { SearchResults.usageBoost(usage[key] ?? 0) }
}
