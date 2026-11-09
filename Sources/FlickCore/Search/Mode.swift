@dynamicMemberLookup
public enum Mode: String, Hashable, CaseIterable {
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

    public var id: String { rawValue }

    public var parent: Mode { self == .models ? .chat : .root }

    public subscript<T>(dynamicMember keyPath: KeyPath<ModeInfo, T>) -> T {
        info[keyPath: keyPath]
    }

    private var info: ModeInfo {
        switch self {
        case .root:
            return ModeInfo(chip: "", placeholder: "Search apps, quicklinks, or Google…", commandTitle: "", commandSubtitle: "",
                            symbol: "magnifyingglass")
        case .emoji:
            return ModeInfo(chip: "Emoji", placeholder: "Search emoji…", commandTitle: "Search Emoji & Symbols",
                            commandSubtitle: "Paste an emoji", symbol: "face.smiling", gridColumns: 9)
        case .snippets:
            return ModeInfo(chip: "Snippets", placeholder: "Search snippets…", commandTitle: "Search Snippets",
                            commandSubtitle: "Paste saved text", symbol: "text.quote")
        case .clipboard:
            return ModeInfo(chip: "Clipboard", placeholder: "Search clipboard history…", commandTitle: "Clipboard History",
                            commandSubtitle: "Paste something you copied earlier", symbol: "doc.on.clipboard", removeLabel: "Delete")
        case .chat:
            return ModeInfo(chip: "AI", placeholder: "Ask anything…", commandTitle: "AI Chat",
                            commandSubtitle: "Chat with AI through OpenRouter", symbol: "sparkles")
        case .models:
            return ModeInfo(chip: "Model", placeholder: "Search models…", commandTitle: "Switch AI Model",
                            commandSubtitle: "Pick the model AI Chat uses", symbol: "cpu", enterLabel: "Use model")
        case .translate:
            return ModeInfo(chip: "Translate", placeholder: "Type text to translate…", commandTitle: "Translate",
                            commandSubtitle: "Translate text with Google Translate", symbol: "character.bubble")
        case .servers:
            return ModeInfo(chip: "Servers", placeholder: "Search live servers…", commandTitle: "Live Servers",
                            commandSubtitle: "Open a local server in the browser", symbol: "server.rack", removeLabel: "Stop")
        case .drives:
            return ModeInfo(chip: "Drives", placeholder: "Search drives…", commandTitle: "Connected Drives",
                            commandSubtitle: "See your drives and eject them", symbol: "eject.fill", aliases: ["Eject"], removeLabel: "Eject")
        case .pullRequests:
            return ModeInfo(chip: "PRs", placeholder: "Search pull requests…", commandTitle: "My Pull Requests",
                            commandSubtitle: "Open a pull request you wrote on GitHub", symbol: "arrow.triangle.pull", aliases: ["GitHub", "PRs"])
        case .timeZones:
            return ModeInfo(chip: "Time", placeholder: "Search cities and time zones…", commandTitle: "Time Zones",
                            commandSubtitle: "See the time anywhere in the world", symbol: "globe", aliases: ["World Clock"])
        case .weather:
            return ModeInfo(chip: "Weather", placeholder: "Search places…", commandTitle: "Weather",
                            commandSubtitle: "See the weather anywhere from yr.no", symbol: "cloud.sun.fill")
        }
    }
}

public struct ModeInfo {
    public let chip: String
    public let placeholder: String
    public let commandTitle: String
    public let commandSubtitle: String
    public let symbol: String
    public var aliases: [String] = []
    public var removeLabel: String?
    public var enterLabel: String?
    public var gridColumns: Int?
}
