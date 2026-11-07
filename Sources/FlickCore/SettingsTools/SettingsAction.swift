import Foundation

public enum SettingsAction: Equatable {
    case listQuicklinks
    case saveQuicklink(Quicklink)
    case deleteQuicklink(UUID)
    case listSnippets
    case saveSnippet(Snippet)
    case deleteSnippet(UUID)
    case getSettings
    case findModels(String)
    case setModel(String?)
    case setTranslateLanguages(TranslatePair)
    case setLaunchAtLogin(Bool)

    struct UnknownTool: LocalizedError {
        let name: String
        var errorDescription: String? { "There is no tool called \(name)." }
    }

    private struct IDArgument: Decodable {
        let id: UUID
    }

    private struct ModelArgument: Decodable {
        let id: String
    }

    private struct QueryArgument: Decodable {
        let query: String
    }

    private struct EnabledArgument: Decodable {
        let enabled: Bool
    }

    public static func parse(_ call: ToolCall) throws -> SettingsAction {
        guard let tool = SettingsTool(rawValue: call.function.name) else { throw UnknownTool(name: call.function.name) }
        let arguments = Data(call.function.arguments.utf8)
        let decoder = JSONDecoder()
        switch tool {
        case .listQuicklinks: return .listQuicklinks
        case .saveQuicklink: return .saveQuicklink(try decoder.decode(Quicklink.self, from: arguments))
        case .deleteQuicklink: return .deleteQuicklink(try decoder.decode(IDArgument.self, from: arguments).id)
        case .listSnippets: return .listSnippets
        case .saveSnippet: return .saveSnippet(try decoder.decode(Snippet.self, from: arguments))
        case .deleteSnippet: return .deleteSnippet(try decoder.decode(IDArgument.self, from: arguments).id)
        case .getSettings: return .getSettings
        case .findModels: return .findModels(try decoder.decode(QueryArgument.self, from: arguments).query)
        case .setModel: return .setModel(try decoder.decode(ModelArgument.self, from: arguments).id)
        case .setTranslateLanguages: return .setTranslateLanguages(try decoder.decode(TranslatePair.self, from: arguments))
        case .setLaunchAtLogin: return .setLaunchAtLogin(try decoder.decode(EnabledArgument.self, from: arguments).enabled)
        }
    }
}
