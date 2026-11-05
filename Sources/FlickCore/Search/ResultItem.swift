import Foundation

public struct AppEntry: Hashable {
    public let name: String
    public let path: String

    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

public enum ResultKind: Equatable {
    case quicklink(Quicklink, argument: String?)
    case app(AppEntry)
    case url(URL)
    case google(String)
    case askAI(String)
    case command(Command)
    case mode(Mode)
    case emoji(Emoji)
    case snippet(Snippet)
    case clip(ClipEntry)
    case message(String)

    public var usageKey: String? {
        switch self {
        case .quicklink(let ql, _): return UsageKey.quicklink(ql)
        case .app(let app): return UsageKey.app(app)
        case .command(let command): return UsageKey.command(command)
        case .mode(let mode): return UsageKey.mode(mode)
        case .emoji(let emoji): return UsageKey.emoji(emoji)
        case .snippet(let snippet): return UsageKey.snippet(snippet)
        default: return nil
        }
    }
}

public enum UsageKey {
    public static func quicklink(_ ql: Quicklink) -> String { "ql:\(ql.id)" }
    public static func app(_ app: AppEntry) -> String { "app:\(app.path)" }
    public static func command(_ command: Command) -> String { "cmd:\(command.id)" }
    public static func emoji(_ emoji: Emoji) -> String { "emoji:\(emoji.character)" }
    public static func snippet(_ snippet: Snippet) -> String { "snippet:\(snippet.id)" }
    public static func mode(_ mode: Mode) -> String { "mode:\(mode.id)" }
}

public struct ResultItem: Identifiable, Equatable {
    public let id: String
    public let kind: ResultKind
    public let title: String
    public let subtitle: String

    public static func quicklink(_ ql: Quicklink, argument: String? = nil) -> ResultItem {
        ResultItem(id: UsageKey.quicklink(ql), kind: .quicklink(ql, argument: argument),
                   title: ql.name, subtitle: subtitle(for: ql, argument: argument))
    }

    public static func app(_ app: AppEntry) -> ResultItem {
        ResultItem(id: UsageKey.app(app), kind: .app(app), title: app.name, subtitle: "")
    }

    public static func command(_ command: Command) -> ResultItem {
        ResultItem(id: UsageKey.command(command), kind: .command(command), title: command.title, subtitle: command.subtitle)
    }

    public static func mode(_ mode: Mode) -> ResultItem {
        ResultItem(id: UsageKey.mode(mode), kind: .mode(mode), title: mode.commandTitle, subtitle: mode.commandSubtitle)
    }

    public static func emoji(_ emoji: Emoji) -> ResultItem {
        ResultItem(id: UsageKey.emoji(emoji), kind: .emoji(emoji), title: emoji.name.capitalized, subtitle: "")
    }

    public static func snippet(_ snippet: Snippet) -> ResultItem {
        let preview = snippet.text.split(whereSeparator: \.isNewline).joined(separator: " ")
        return ResultItem(id: UsageKey.snippet(snippet), kind: .snippet(snippet), title: snippet.name, subtitle: preview)
    }

    public static func clip(_ entry: ClipEntry, now: Date) -> ResultItem {
        let age = ClipHistory.age(of: entry.copiedAt, now: now)
        let subtitle = [entry.appName, age].compactMap { $0 }.joined(separator: " · ")
        return ResultItem(id: "clip:\(entry.id)", kind: .clip(entry), title: ClipHistory.title(of: entry.text), subtitle: subtitle)
    }

    public static func url(_ url: URL, typed: String) -> ResultItem {
        ResultItem(id: "url", kind: .url(url), title: "Open \(typed)", subtitle: url.absoluteString)
    }

    public static func google(_ query: String) -> ResultItem {
        ResultItem(id: "google", kind: .google(query), title: "Search Google for \u{201C}\(query)\u{201D}", subtitle: "google.com")
    }

    public static func askAI(_ question: String) -> ResultItem {
        ResultItem(id: "askAI", kind: .askAI(question), title: "Ask AI \u{201C}\(question)\u{201D}", subtitle: "OpenRouter")
    }

    public static func message(_ text: String) -> ResultItem {
        ResultItem(id: "message", kind: .message(text), title: "Quicklinks file has an error", subtitle: text)
    }

    private static func subtitle(for ql: Quicklink, argument: String?) -> String {
        if let argument, !argument.isEmpty { return ql.resolved(argument: argument) }
        if ql.takesArgument { return "Press ⇥ to add a \(ql.argumentLabel.lowercased())" }
        return ql.link
    }
}
