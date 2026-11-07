import Foundation

public struct AgentOutcome: Equatable {
    public let output: String
    public let change: AgentChange?
}

public struct AgentWorkspace: Equatable {
    public var quicklinks: [Quicklink]
    public var snippets: [Snippet]

    public init(quicklinks: [Quicklink], snippets: [Snippet]) {
        self.quicklinks = quicklinks
        self.snippets = snippets
    }

    public mutating func perform(_ call: AgentToolCall) -> AgentOutcome {
        do {
            return try perform(AgentAction.parse(call))
        } catch {
            return AgentOutcome(output: "Error: \(error.localizedDescription)", change: nil)
        }
    }

    mutating func perform(_ action: AgentAction) throws -> AgentOutcome {
        switch action {
        case .listQuicklinks:
            return AgentOutcome(output: try Self.json(quicklinks), change: nil)
        case .listSnippets:
            return AgentOutcome(output: try Self.json(snippets), change: nil)
        case .saveQuicklink(let link):
            let kind: AgentChange.Kind = quicklinks.upsert(link) ? .updated : .added
            return AgentOutcome(output: "Saved quicklink with id \(link.id).", change: .quicklink(kind, link))
        case .saveSnippet(let snippet):
            let kind: AgentChange.Kind = snippets.upsert(snippet) ? .updated : .added
            return AgentOutcome(output: "Saved snippet with id \(snippet.id).", change: .snippet(kind, snippet))
        case .deleteQuicklink(let id):
            guard let link = quicklinks.remove(id: id) else { return Self.notFound("quicklink", id) }
            return AgentOutcome(output: "Deleted.", change: .quicklink(.removed, link))
        case .deleteSnippet(let id):
            guard let snippet = snippets.remove(id: id) else { return Self.notFound("snippet", id) }
            return AgentOutcome(output: "Deleted.", change: .snippet(.removed, snippet))
        }
    }

    private static func notFound(_ item: String, _ id: UUID) -> AgentOutcome {
        AgentOutcome(output: "Error: no \(item) has id \(id).", change: nil)
    }

    private static func json<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try JSONEncoder().encode(value), as: UTF8.self)
    }
}
