public struct SettingsChange: Equatable {
    public enum Kind: Equatable {
        case added, updated, removed
    }

    public let kind: Kind
    public let item: String
    public let name: String
    public let detail: String
    public let undo: SettingsAction

    public var title: String {
        [verb, item, name].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private var verb: String {
        switch kind {
        case .added: return "Added"
        case .updated: return "Updated"
        case .removed: return "Removed"
        }
    }
}

extension SettingsChange {
    static func quicklink(_ kind: Kind, _ link: Quicklink, undo: SettingsAction) -> SettingsChange {
        SettingsChange(kind: kind, item: "quicklink", name: link.name, detail: detail(keyword: link.keyword, link.link), undo: undo)
    }

    static func snippet(_ kind: Kind, _ snippet: Snippet, undo: SettingsAction) -> SettingsChange {
        SettingsChange(kind: kind, item: "snippet", name: snippet.name, detail: detail(keyword: snippet.keyword, snippet.text), undo: undo)
    }

    static func setting(_ name: String, _ value: String, undo: SettingsAction) -> SettingsChange {
        SettingsChange(kind: .updated, item: "", name: name, detail: value, undo: undo)
    }

    private static func detail(keyword: String?, _ value: String) -> String {
        [keyword, value].compactMap { $0 }.joined(separator: " · ")
    }
}
