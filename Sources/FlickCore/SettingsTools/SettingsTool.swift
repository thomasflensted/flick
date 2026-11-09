import Foundation

struct SettingsTool {
    let name: String
    let description: String
    var parameters: [Parameter] = []
    let parse: (Data) throws -> SettingsAction

    struct Parameter {
        let name: String
        var type = "string"
        let description: String
        let required: Bool
    }

    struct UnknownTool: LocalizedError {
        let name: String
        var errorDescription: String? { "There is no tool called \(name)." }
    }

    static func action(for call: ToolCall) throws -> SettingsAction {
        guard let tool = all.first(where: { $0.name == call.function.name }) else { throw UnknownTool(name: call.function.name) }
        return try tool.parse(Data(call.function.arguments.utf8))
    }

    static let all: [SettingsTool] = [
        listQuicklinks, saveQuicklink, deleteQuicklink, listSnippets, saveSnippet, deleteSnippet,
        getSettings, findModels, setModel, setTranslateLanguages, setLaunchAtLogin, setSyncFolder,
    ]

    static let listQuicklinks = SettingsTool(name: "list_quicklinks", description: "List all quicklinks with their ids.") { _ in .listQuicklinks }

    static let saveQuicklink = SettingsTool(
        name: "save_quicklink",
        description: "Add a quicklink, or replace an existing one when id is given. Pass every field you want to keep.",
        parameters: [
            editIDParameter,
            Parameter(name: "name", description: "Title shown in search.", required: true),
            Parameter(name: "link", description: "URL, app URL scheme or file path. May contain {argument}.", required: true),
            Parameter(name: "keyword", description: "Optional short alias.", required: false),
            Parameter(name: "openWith", description: "Optional bundle id or .app path to open the link with.", required: false),
        ]
    ) { .saveQuicklink(try decode(Quicklink.self, $0)) }

    static let deleteQuicklink = SettingsTool(name: "delete_quicklink", description: "Delete a quicklink.", parameters: [idParameter]) {
        .deleteQuicklink(try decode(IDArgument.self, $0).id)
    }

    static let listSnippets = SettingsTool(name: "list_snippets", description: "List all snippets with their ids.") { _ in .listSnippets }

    static let saveSnippet = SettingsTool(
        name: "save_snippet",
        description: "Add a snippet, or replace an existing one when id is given. Pass every field you want to keep.",
        parameters: [
            editIDParameter,
            Parameter(name: "name", description: "Title shown in search.", required: true),
            Parameter(name: "text", description: "Text to insert. May contain {id}.", required: true),
            Parameter(name: "keyword", description: "Optional text that expands into the snippet when typed.", required: false),
        ]
    ) { .saveSnippet(try decode(Snippet.self, $0)) }

    static let deleteSnippet = SettingsTool(name: "delete_snippet", description: "Delete a snippet.", parameters: [idParameter]) {
        .deleteSnippet(try decode(IDArgument.self, $0).id)
    }

    static let getSettings = SettingsTool(
        name: "get_settings",
        description: "Get the current AI model, translate languages, launch-at-login setting, sync folder and the cloud folders on this Mac."
    ) { _ in .getSettings }

    static let findModels = SettingsTool(
        name: "find_models",
        description: "Search the AI models available on OpenRouter by name or id.",
        parameters: [Parameter(name: "query", description: "Words to search for, e.g. claude sonnet.", required: true)]
    ) { .findModels(try decode(QueryArgument.self, $0).query) }

    static let setModel = SettingsTool(
        name: "set_model",
        description: "Change the AI model used by the chat. Takes effect from the next message.",
        parameters: [Parameter(name: "id", description: "Model id from find_models.", required: true)]
    ) { .setModel(try decode(ModelArgument.self, $0).id) }

    static let setTranslateLanguages = SettingsTool(
        name: "set_translate_languages",
        description: "Set the default languages for Translate. Omit a language to let Flick pick it automatically.",
        parameters: [
            Parameter(name: "source", description: "Language code to translate from. Omit to detect it.", required: false),
            Parameter(name: "target", description: "Language code to translate to. Omit to use the user's languages.", required: false),
        ]
    ) { .setTranslateLanguages(try decode(TranslatePair.self, $0)) }

    static let setLaunchAtLogin = SettingsTool(
        name: "set_launch_at_login",
        description: "Turn starting Flick when the user logs in on or off.",
        parameters: [Parameter(name: "enabled", type: "boolean", description: "Whether Flick starts at login.", required: true)]
    ) { .setLaunchAtLogin(try decode(EnabledArgument.self, $0).enabled) }

    static let setSyncFolder = SettingsTool(
        name: "set_sync_folder",
        description: "Store quicklinks and snippets in a folder that a cloud service syncs between the user's Macs. Omit path to store them on this Mac only.",
        parameters: [Parameter(name: "path", description: "Absolute path of the folder, e.g. a Flick folder inside a cloud folder from get_settings.", required: false)]
    ) { .setSyncFolder(try decode(PathArgument.self, $0).path) }

    private static let idParameter = Parameter(name: "id", description: "Id of an existing item.", required: true)
    private static let editIDParameter = Parameter(name: "id", description: "Id of the item to edit. Omit to add a new one.", required: false)

    private struct IDArgument: Decodable { let id: UUID }
    private struct ModelArgument: Decodable { let id: String }
    private struct QueryArgument: Decodable { let query: String }
    private struct EnabledArgument: Decodable { let enabled: Bool }
    private struct PathArgument: Decodable { let path: String? }

    private static func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
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
        function = Function(name: tool.name, description: tool.description, parameters: schema)
    }

    static let all = SettingsTool.all.map(ToolDefinition.init)
}
