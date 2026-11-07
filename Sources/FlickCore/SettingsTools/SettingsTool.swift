import Foundation

public enum SettingsTool: String, CaseIterable {
    case listQuicklinks = "list_quicklinks"
    case saveQuicklink = "save_quicklink"
    case deleteQuicklink = "delete_quicklink"
    case listSnippets = "list_snippets"
    case saveSnippet = "save_snippet"
    case deleteSnippet = "delete_snippet"
    case getSettings = "get_settings"
    case findModels = "find_models"
    case setModel = "set_model"
    case setTranslateLanguages = "set_translate_languages"
    case setLaunchAtLogin = "set_launch_at_login"

    private static let idParameter = Parameter(name: "id", description: "Id of an existing item.", required: true)
    private static let editIDParameter = Parameter(name: "id", description: "Id of the item to edit. Omit to add a new one.", required: false)

    var description: String {
        switch self {
        case .listQuicklinks: return "List all quicklinks with their ids."
        case .saveQuicklink: return "Add a quicklink, or replace an existing one when id is given. Pass every field you want to keep."
        case .deleteQuicklink: return "Delete a quicklink."
        case .listSnippets: return "List all snippets with their ids."
        case .saveSnippet: return "Add a snippet, or replace an existing one when id is given. Pass every field you want to keep."
        case .deleteSnippet: return "Delete a snippet."
        case .getSettings: return "Get the current AI model, translate languages and launch-at-login setting."
        case .findModels: return "Search the AI models available on OpenRouter by name or id."
        case .setModel: return "Change the AI model used by the chat. Takes effect from the next message."
        case .setTranslateLanguages: return "Set the default languages for Translate. Omit a language to let Flick pick it automatically."
        case .setLaunchAtLogin: return "Turn starting Flick when the user logs in on or off."
        }
    }

    var parameters: [Parameter] {
        switch self {
        case .listQuicklinks, .listSnippets, .getSettings: return []
        case .findModels: return [Parameter(name: "query", description: "Words to search for, e.g. claude sonnet.", required: true)]
        case .setModel: return [Parameter(name: "id", description: "Model id from find_models.", required: true)]
        case .setTranslateLanguages:
            return [
                Parameter(name: "source", description: "Language code to translate from. Omit to detect it.", required: false),
                Parameter(name: "target", description: "Language code to translate to. Omit to use the user's languages.", required: false),
            ]
        case .setLaunchAtLogin: return [Parameter(name: "enabled", type: "boolean", description: "Whether Flick starts at login.", required: true)]
        case .deleteQuicklink, .deleteSnippet: return [Self.idParameter]
        case .saveQuicklink:
            return [
                Self.editIDParameter,
                Parameter(name: "name", description: "Title shown in search.", required: true),
                Parameter(name: "link", description: "URL, app URL scheme or file path. May contain {argument}.", required: true),
                Parameter(name: "keyword", description: "Optional short alias.", required: false),
                Parameter(name: "openWith", description: "Optional bundle id or .app path to open the link with.", required: false),
            ]
        case .saveSnippet:
            return [
                Self.editIDParameter,
                Parameter(name: "name", description: "Title shown in search.", required: true),
                Parameter(name: "text", description: "Text to insert. May contain {id}.", required: true),
                Parameter(name: "keyword", description: "Optional text that expands into the snippet when typed.", required: false),
            ]
        }
    }

    struct Parameter {
        let name: String
        var type = "string"
        let description: String
        let required: Bool
    }
}

struct ToolDefinition: Encodable {
    struct Function: Encodable {
        let name: String
        let description: String
        let parameters: Schema
    }

    struct Schema: Encodable {
        struct Property: Encodable {
            let type: String
            let description: String
        }

        let type = "object"
        let properties: [String: Property]
        let required: [String]
    }

    let type = "function"
    let function: Function

    init(_ tool: SettingsTool) {
        let properties = Dictionary(uniqueKeysWithValues: tool.parameters.map { ($0.name, Schema.Property(type: $0.type, description: $0.description)) })
        let schema = Schema(properties: properties, required: tool.parameters.filter(\.required).map(\.name))
        function = Function(name: tool.rawValue, description: tool.description, parameters: schema)
    }

    static let all = SettingsTool.allCases.map(ToolDefinition.init)
}
