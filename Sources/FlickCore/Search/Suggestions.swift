public enum Suggestions {
    public static func results(_ suggestions: [String], for ql: Quicklink) -> [ResultItem] {
        [.quicklink(ql)] + suggestions.map { .suggestion($0, for: ql) }
    }

    public static func placeText(title: String, subtitle: String) -> String {
        subtitle.isEmpty ? title : "\(title), \(subtitle)"
    }
}
