import Foundation

struct SettingsOutcome: Equatable {
    let output: String
    let change: SettingsChange?
}

public struct SettingsWorkspace: Equatable {
    public var quicklinks: [Quicklink]
    public var snippets: [Snippet]
    public var modelID: String?
    public var translatePair: TranslatePair
    public var launchAtLogin: Bool
    let models: [AIModel]

    static let maxModelMatches = 10
    private static let languageNames = Locale(identifier: "en")

    public init(quicklinks: [Quicklink], snippets: [Snippet], modelID: String? = nil, translatePair: TranslatePair = TranslatePair(),
                launchAtLogin: Bool = false, models: [AIModel] = []) {
        self.quicklinks = quicklinks
        self.snippets = snippets
        self.modelID = modelID
        self.translatePair = translatePair
        self.launchAtLogin = launchAtLogin
        self.models = models
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
            guard let link = quicklinks.remove(id: id) else { return Self.failure("no quicklink has id \(id).") }
            return SettingsOutcome(output: "Deleted.", change: .quicklink(.removed, link, undo: .saveQuicklink(link)))
        case .deleteSnippet(let id):
            guard let snippet = snippets.remove(id: id) else { return Self.failure("no snippet has id \(id).") }
            return SettingsOutcome(output: "Deleted.", change: .snippet(.removed, snippet, undo: .saveSnippet(snippet)))
        case .getSettings:
            return SettingsOutcome(output: try Self.json(CurrentSettings(self)), change: nil)
        case .findModels(let query):
            return SettingsOutcome(output: try Self.json(matchingModels(query)), change: nil)
        case .setModel(let id):
            return setModel(id)
        case .setTranslateLanguages(let pair):
            return setTranslateLanguages(pair)
        case .setLaunchAtLogin(let enabled):
            let change = SettingsChange.setting("Launch at login", enabled ? "On" : "Off", undo: .setLaunchAtLogin(launchAtLogin))
            launchAtLogin = enabled
            return SettingsOutcome(output: "Launch at login is \(enabled ? "on" : "off").", change: change)
        }
    }

    private func matchingModels(_ query: String) -> [ModelMatch] {
        ModelCatalog.search(query, in: models.filter { !$0.isVariant }).prefix(Self.maxModelMatches).map(ModelMatch.init)
    }

    private mutating func setModel(_ id: String?) -> SettingsOutcome {
        let model = models.first { $0.id == id }
        guard id == nil || model != nil else { return Self.failure("no model has id \(id ?? ""). Use find_models.") }
        let change = SettingsChange.setting("AI model", model?.name ?? "None", undo: .setModel(modelID))
        modelID = id
        return SettingsOutcome(output: "The next message will use \(id ?? "no model").", change: change)
    }

    private mutating func setTranslateLanguages(_ pair: TranslatePair) -> SettingsOutcome {
        let unknown = [pair.source, pair.target].compactMap { $0 }.filter { !Language.codes.contains($0) }
        guard unknown.isEmpty else {
            return Self.failure("unsupported language \(unknown.joined(separator: ", ")). Supported: \(Language.codes.joined(separator: ", ")).")
        }
        let change = SettingsChange.setting("Translate languages", Self.describe(pair), undo: .setTranslateLanguages(translatePair))
        translatePair = pair
        return SettingsOutcome(output: "Translate now goes \(Self.describe(pair)).", change: change)
    }

    private static func describe(_ pair: TranslatePair) -> String {
        let source = pair.source.map { Language.name(of: $0, in: languageNames) } ?? "Detected language"
        let target = pair.target.map { Language.name(of: $0, in: languageNames) } ?? "your languages"
        return "\(source) → \(target)"
    }

    private static func failure(_ message: String) -> SettingsOutcome {
        SettingsOutcome(output: "Error: \(message)", change: nil)
    }

    private static func json<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }
}

private struct CurrentSettings: Encodable {
    let model: String?
    let translate: TranslatePair
    let launchAtLogin: Bool

    init(_ workspace: SettingsWorkspace) {
        model = workspace.modelID
        translate = workspace.translatePair
        launchAtLogin = workspace.launchAtLogin
    }
}

private struct ModelMatch: Encodable {
    let id: String
    let name: String
    let price: String?
    let supportsTools: Bool

    init(_ model: AIModel) {
        id = model.id
        name = model.name
        price = model.priceText
        supportsTools = model.supportsTools
    }
}
