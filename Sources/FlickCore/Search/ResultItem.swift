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
    case message(String)

    public var usageKey: String? {
        switch self {
        case .quicklink(let ql, _): return UsageKey.quicklink(ql)
        case .app(let app): return UsageKey.app(app)
        default: return nil
        }
    }
}

public enum UsageKey {
    public static func quicklink(_ ql: Quicklink) -> String { "ql:\(ql.id)" }
    public static func app(_ app: AppEntry) -> String { "app:\(app.path)" }
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
        ResultItem(id: UsageKey.app(app), kind: .app(app), title: app.name, subtitle: "Application")
    }

    public static func url(_ url: URL, typed: String) -> ResultItem {
        ResultItem(id: "url", kind: .url(url), title: "Open \(typed)", subtitle: url.absoluteString)
    }

    public static func google(_ query: String) -> ResultItem {
        ResultItem(id: "google", kind: .google(query), title: "Search Google for \u{201C}\(query)\u{201D}", subtitle: "google.com")
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
