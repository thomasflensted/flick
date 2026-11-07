import Foundation

public enum SettingsAction: Equatable {
    case listQuicklinks
    case saveQuicklink(Quicklink)
    case deleteQuicklink(UUID)
    case listSnippets
    case saveSnippet(Snippet)
    case deleteSnippet(UUID)

    struct UnknownTool: LocalizedError {
        let name: String
        var errorDescription: String? { "There is no tool called \(name)." }
    }

    private struct IDArgument: Decodable {
        let id: UUID
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
        }
    }
}
