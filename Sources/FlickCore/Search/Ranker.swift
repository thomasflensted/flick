public struct Ranker {
    public let usage: [String: Int]

    public init(usage: [String: Int]) {
        self.usage = usage
    }

    public func rank<T>(_ items: [T], query: String, texts: (T) -> [String], key: (T) -> String) -> [T] {
        let query = query.trimmingCharacters(in: .whitespaces)
        let scored = items.enumerated().compactMap { index, item in
            score(item, query: query, texts: texts, key: key).map { (score: $0, index: index, item: item) }
        }
        return scored.sorted { ($0.score, -$0.index) > ($1.score, -$1.index) }.map(\.item)
    }

    func score<T>(_ item: T, query: String, texts: (T) -> [String], key: (T) -> String) -> Int? {
        texts(item).compactMap { MatchScore.score(query, against: $0) }.max().map { $0 + boost(key(item)) }
    }

    func boost(_ key: String) -> Int { Self.usageBoost(usage[key] ?? 0) }

    static func usageBoost(_ count: Int) -> Int { min(count * 30, 300) }
}
