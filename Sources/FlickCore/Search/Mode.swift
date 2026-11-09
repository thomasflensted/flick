public enum Mode: Hashable, CaseIterable {
    case root
    case emoji
    case snippets
    case clipboard
    case chat
    case models
    case translate
    case servers
    case drives
    case pullRequests
    case timeZones
    case weather

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
        case .drives: return nil
        case .pullRequests: return nil
        case .timeZones: return nil
        case .weather: return nil
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
        case .drives: return "drives"
        case .pullRequests: return "pullRequests"
        case .timeZones: return "timeZones"
        case .weather: return "weather"
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
        case .drives: return "Drives"
        case .pullRequests: return "PRs"
        case .timeZones: return "Time"
        case .weather: return "Weather"
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
        case .drives: return "Search drives…"
        case .pullRequests: return "Search pull requests…"
        case .timeZones: return "Search cities and time zones…"
        case .weather: return "Search places…"
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
        case .drives: return "Connected Drives"
        case .pullRequests: return "My Pull Requests"
        case .timeZones: return "Time Zones"
        case .weather: return "Weather"
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
        case .drives: return "See your drives and eject them"
        case .pullRequests: return "Open a pull request you wrote on GitHub"
        case .timeZones: return "See the time anywhere in the world"
        case .weather: return "See the weather anywhere from yr.no"
        }
    }

    public var removeLabel: String? {
        switch self {
        case .clipboard: return "Delete"
        case .servers: return "Stop"
        case .drives: return "Eject"
        case .root, .emoji, .snippets, .chat, .models, .translate, .timeZones, .weather, .pullRequests: return nil
        }
    }

    public var aliases: [String] {
        switch self {
        case .drives: return ["Eject"]
        case .pullRequests: return ["GitHub", "PRs"]
        case .timeZones: return ["World Clock"]
        default: return []
        }
    }

    public var enterLabel: String? {
        switch self {
        case .models: return "Use model"
        case .root, .emoji, .snippets, .clipboard, .chat, .translate, .servers, .drives, .timeZones, .weather, .pullRequests: return nil
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
        case .drives: return "eject.fill"
        case .pullRequests: return "arrow.triangle.pull"
        case .timeZones: return "globe"
        case .weather: return "cloud.sun.fill"
        }
    }
}
