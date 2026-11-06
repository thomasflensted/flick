import Foundation

public enum GoogleSuggest {
    static let limit = 5

    struct Malformed: Error {}

    public static func results(suggestions: [String]) -> [ResultItem] {
        [.quicklink(.googleSearch)] + suggestions.map { .suggestion($0, for: .googleSearch) }
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
