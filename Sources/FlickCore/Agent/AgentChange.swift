public struct AgentChange: Equatable {
    public enum Kind: Equatable {
        case added, updated, removed
    }

    public let kind: Kind
    public let item: String
    public let name: String
    public let detail: String

    public var title: String {
        "\(verb) \(item) \(name)"
    }

    private var verb: String {
        switch kind {
        case .added: return "Added"
        case .updated: return "Updated"
        case .removed: return "Removed"
        }
    }
}

extension AgentChange {
    static func quicklink(_ kind: Kind, _ link: Quicklink) -> AgentChange {
        AgentChange(kind: kind, item: "quicklink", name: link.name, detail: detail(keyword: link.keyword, link.link))
    }

    static func snippet(_ kind: Kind, _ snippet: Snippet) -> AgentChange {
        AgentChange(kind: kind, item: "snippet", name: snippet.name, detail: detail(keyword: snippet.keyword, snippet.text))
    }

    private static func detail(keyword: String?, _ value: String) -> String {
        [keyword, value].compactMap { $0 }.joined(separator: " · ")
    }
}
