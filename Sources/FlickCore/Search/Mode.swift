public enum Mode: Hashable, CaseIterable {
    case root
    case emoji
    case snippets
    case clipboard
    case chat

    public static var openable: [Mode] { allCases.filter { $0 != .root } }

    public var gridColumns: Int? {
        switch self {
        case .root: return nil
        case .emoji: return 9
        case .snippets: return nil
        case .clipboard: return nil
        case .chat: return nil
        }
    }

    public var id: String {
        switch self {
        case .root: return "root"
        case .emoji: return "emoji"
        case .snippets: return "snippets"
        case .clipboard: return "clipboard"
        case .chat: return "chat"
        }
    }

    public var chip: String {
        switch self {
        case .root: return ""
        case .emoji: return "Emoji"
        case .snippets: return "Snippets"
        case .clipboard: return "Clipboard"
        case .chat: return "AI"
        }
    }

    public var placeholder: String {
        switch self {
        case .root: return "Search apps, quicklinks, or Google…"
        case .emoji: return "Search emoji…"
        case .snippets: return "Search snippets…"
        case .clipboard: return "Search clipboard history…"
        case .chat: return "Ask anything…"
        }
    }

    public var commandTitle: String {
        switch self {
        case .root: return ""
        case .emoji: return "Search Emoji & Symbols"
        case .snippets: return "Search Snippets"
        case .clipboard: return "Clipboard History"
        case .chat: return "AI Chat"
        }
    }

    public var commandSubtitle: String {
        switch self {
        case .root: return ""
        case .emoji: return "Paste an emoji"
        case .snippets: return "Paste saved text"
        case .clipboard: return "Paste something you copied earlier"
        case .chat: return "Chat with AI through OpenRouter"
        }
    }

    public var symbol: String {
        switch self {
        case .root: return "magnifyingglass"
        case .emoji: return "face.smiling"
        case .snippets: return "text.quote"
        case .clipboard: return "doc.on.clipboard"
        case .chat: return "sparkles"
        }
    }
}
