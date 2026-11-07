import Foundation

struct SettingsOutcome: Equatable {
    let output: String
    let change: SettingsChange?
}

public struct SettingsWorkspace: Equatable {
    public var quicklinks: [Quicklink]
    public var snippets: [Snippet]

    public init(quicklinks: [Quicklink], snippets: [Snippet]) {
        self.quicklinks = quicklinks
        self.snippets = snippets
    }

    public mutating func perform(_ call: ToolCall) -> ToolResult {
        do {
            let outcome = try perform(SettingsAction.parse(call))
            return ToolResult(callID: call.id, output: outcome.output, change: outcome.change)
        } catch {
            return ToolResult(callID: call.id, output: "Error: \(error.localizedDescription)")
        }
    }

    public mutating func revert(_ change: SettingsChange) {
        _ = try? perform(change.undo)
    }

    mutating func perform(_ action: SettingsAction) throws -> SettingsOutcome {
        switch action {
        case .listQuicklinks:
            return SettingsOutcome(output: try Self.json(quicklinks), change: nil)
        case .listSnippets:
            return SettingsOutcome(output: try Self.json(snippets), change: nil)
        case .saveQuicklink(let link):
            let change: SettingsChange = quicklinks.upsert(link).map { .quicklink(.updated, link, undo: .saveQuicklink($0)) }
                ?? .quicklink(.added, link, undo: .deleteQuicklink(link.id))
            return SettingsOutcome(output: "Saved quicklink with id \(link.id).", change: change)
        case .saveSnippet(let snippet):
            let change: SettingsChange = snippets.upsert(snippet).map { .snippet(.updated, snippet, undo: .saveSnippet($0)) }
                ?? .snippet(.added, snippet, undo: .deleteSnippet(snippet.id))
            return SettingsOutcome(output: "Saved snippet with id \(snippet.id).", change: change)
        case .deleteQuicklink(let id):
            guard let link = quicklinks.remove(id: id) else { return Self.notFound("quicklink", id) }
            return SettingsOutcome(output: "Deleted.", change: .quicklink(.removed, link, undo: .saveQuicklink(link)))
        case .deleteSnippet(let id):
            guard let snippet = snippets.remove(id: id) else { return Self.notFound("snippet", id) }
            return SettingsOutcome(output: "Deleted.", change: .snippet(.removed, snippet, undo: .saveSnippet(snippet)))
        }
    }

    private static func notFound(_ item: String, _ id: UUID) -> SettingsOutcome {
        SettingsOutcome(output: "Error: no \(item) has id \(id).", change: nil)
    }

    private static func json<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try JSONEncoder().encode(value), as: UTF8.self)
    }
}
