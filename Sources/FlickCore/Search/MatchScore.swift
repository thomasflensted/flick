public enum MatchScore {
    public static let exact = 1000
    public static let prefix = 800
    public static let wordPrefix = 600
    public static let initials = 500
    public static let substring = 400
    public static let subsequence = 200

    public static func score(_ query: String, against target: String) -> Int? {
        let q = query.lowercased(), t = target.lowercased()
        if q.isEmpty { return 0 }
        if t == q { return exact }
        if t.hasPrefix(q) { return prefix }
        let words = t.split { !$0.isLetter && !$0.isNumber }
        if words.contains(where: { $0.hasPrefix(q) }) { return wordPrefix }
        if String(words.compactMap(\.first)).hasPrefix(q) { return initials }
        if t.contains(q) { return substring }
        return isSubsequence(q, of: t) ? subsequence : nil
    }

    private static func isSubsequence(_ needle: String, of haystack: String) -> Bool {
        var rest = haystack[...]
        for c in needle {
            guard let i = rest.firstIndex(of: c) else { return false }
            rest = rest[rest.index(after: i)...]
        }
        return true
    }
}
