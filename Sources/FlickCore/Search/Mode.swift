public enum Mode: Hashable, CaseIterable {
    case root
    case emoji

    public static var openable: [Mode] { allCases.filter { $0 != .root } }

    public var id: String {
        switch self {
        case .root: return "root"
        case .emoji: return "emoji"
        }
    }

    public var chip: String {
        switch self {
        case .root: return ""
        case .emoji: return "Emoji"
        }
    }

    public var placeholder: String {
        switch self {
        case .root: return "Search apps, quicklinks, or Google…"
        case .emoji: return "Search emoji…"
        }
    }

    public var commandTitle: String {
        switch self {
        case .root: return ""
        case .emoji: return "Search Emoji & Symbols"
        }
    }

    public var commandSubtitle: String {
        switch self {
        case .root: return ""
        case .emoji: return "Paste an emoji"
        }
    }

    public var symbol: String {
        switch self {
        case .root: return "magnifyingglass"
        case .emoji: return "face.smiling"
        }
    }
}
