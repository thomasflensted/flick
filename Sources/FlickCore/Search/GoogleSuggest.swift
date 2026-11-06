import Foundation

public enum GoogleSuggest {
    static let limit = 5

    struct Malformed: Error {}

    public static func supports(_ ql: Quicklink) -> Bool {
        guard ql.takesArgument, let url = URLText.url(from: ql.resolved(argument: "x")),
              let host = url.host?.lowercased() else { return false }
        return host.split(separator: ".").contains("google") && url.path == "/search"
    }

    public static func results(for ql: Quicklink, suggestions: [String]) -> [ResultItem] {
        [.quicklink(ql)] + suggestions.map { .suggestion($0, for: ql) }
    }

    public static func requestURL(query: String) -> URL {
        var components = URLComponents(string: "https://suggestqueries.google.com/complete/search")!
        components.queryItems = [.init(name: "client", value: "firefox"), .init(name: "q", value: query)]
        return components.url!
    }

    public static func parse(_ data: Data, query: String) throws -> [String] {
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        guard let suggestions = json[1]?.array else { throw Malformed() }
        let typed = query.lowercased()
        return Array(suggestions.compactMap(\.string).filter { $0.lowercased() != typed }.prefix(limit))
    }
}
