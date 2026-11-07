public enum Mode: Hashable, CaseIterable {
    case root
    case emoji
    case snippets
    case clipboard
    case chat
    case agent
    case translate
    case servers

    public static var openable: [Mode] { allCases.filter { $0 != .root } }

    public var gridColumns: Int? {
        switch self {
        case .root: return nil
        case .emoji: return 9
        case .snippets: return nil
        case .clipboard: return nil
        case .chat: return nil
        case .agent: return nil
        case .translate: return nil
        case .servers: return nil
        }
    }

    public var id: String {
        switch self {
        case .root: return "root"
        case .emoji: return "emoji"
        case .snippets: return "snippets"
        case .clipboard: return "clipboard"
        case .chat: return "chat"
        case .agent: return "agent"
        case .translate: return "translate"
        case .servers: return "servers"
        }
    }

    public var chip: String {
        switch self {
        case .root: return ""
        case .emoji: return "Emoji"
        case .snippets: return "Snippets"
        case .clipboard: return "Clipboard"
        case .chat: return "AI"
        case .agent: return "Agent"
        case .translate: return "Translate"
        case .servers: return "Servers"
        }
    }

    public var placeholder: String {
        switch self {
        case .root: return "Search apps, quicklinks, or Google…"
        case .emoji: return "Search emoji…"
        case .snippets: return "Search snippets…"
        case .clipboard: return "Search clipboard history…"
        case .chat: return "Ask anything…"
        case .agent: return "Ask to add or change quicklinks and snippets…"
        case .translate: return "Type text to translate…"
        case .servers: return "Search live servers…"
        }
    }

    public var commandTitle: String {
        switch self {
        case .root: return ""
        case .emoji: return "Search Emoji & Symbols"
        case .snippets: return "Search Snippets"
        case .clipboard: return "Clipboard History"
        case .chat: return "AI Chat"
        case .agent: return "Flick Agent"
        case .translate: return "Translate"
        case .servers: return "Live Servers"
        }
    }

    public var commandSubtitle: String {
        switch self {
        case .root: return ""
        case .emoji: return "Paste an emoji"
        case .snippets: return "Paste saved text"
        case .clipboard: return "Paste something you copied earlier"
        case .chat: return "Chat with AI through OpenRouter"
        case .agent: return "Add or change quicklinks and snippets with AI"
        case .translate: return "Translate text with Google Translate"
        case .servers: return "Open a local server in the browser"
        }
    }

    public var removeLabel: String? {
        switch self {
        case .clipboard: return "Delete"
        case .servers: return "Stop"
        case .root, .emoji, .snippets, .chat, .agent, .translate: return nil
        }
    }

    public var isConversation: Bool { self == .chat || self == .agent }

    public var symbol: String {
        switch self {
        case .root: return "magnifyingglass"
        case .emoji: return "face.smiling"
        case .snippets: return "text.quote"
        case .clipboard: return "doc.on.clipboard"
        case .chat: return "sparkles"
        case .agent: return "wand.and.stars"
        case .translate: return "character.bubble"
        case .servers: return "server.rack"
        }
    }
}
