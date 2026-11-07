public enum Mode: Hashable, CaseIterable {
    case root
    case emoji
    case snippets
    case clipboard
    case chat
    case models
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
        case .models: return nil
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
        case .models: return "models"
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
        case .models: return "Model"
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
        case .models: return "Search models…"
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
        case .models: return "Switch AI Model"
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
        case .models: return "Pick the model AI Chat uses"
        case .translate: return "Translate text with Google Translate"
        case .servers: return "Open a local server in the browser"
        }
    }

    public var removeLabel: String? {
        switch self {
        case .clipboard: return "Delete"
        case .servers: return "Stop"
        case .root, .emoji, .snippets, .chat, .models, .translate: return nil
        }
    }

    public var parent: Mode {
        self == .models ? .chat : .root
    }

    public var symbol: String {
        switch self {
        case .root: return "magnifyingglass"
        case .emoji: return "face.smiling"
        case .snippets: return "text.quote"
        case .clipboard: return "doc.on.clipboard"
        case .chat: return "sparkles"
        case .models: return "cpu"
        case .translate: return "character.bubble"
        case .servers: return "server.rack"
        }
    }
}
