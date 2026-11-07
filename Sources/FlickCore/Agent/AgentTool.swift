import Foundation

public enum AgentTool: String, CaseIterable {
    case listQuicklinks = "list_quicklinks"
    case saveQuicklink = "save_quicklink"
    case deleteQuicklink = "delete_quicklink"
    case listSnippets = "list_snippets"
    case saveSnippet = "save_snippet"
    case deleteSnippet = "delete_snippet"

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
        }
    }

    var parameters: [Parameter] {
        switch self {
        case .listQuicklinks, .listSnippets: return []
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
            let type = "string"
            let description: String
        }

        let type = "object"
        let properties: [String: Property]
        let required: [String]
    }

    let type = "function"
    let function: Function

    init(_ tool: AgentTool) {
        let properties = Dictionary(uniqueKeysWithValues: tool.parameters.map { ($0.name, Schema.Property(description: $0.description)) })
        let schema = Schema(properties: properties, required: tool.parameters.filter(\.required).map(\.name))
        function = Function(name: tool.rawValue, description: tool.description, parameters: schema)
    }

    static let all = AgentTool.allCases.map(ToolDefinition.init)
}
