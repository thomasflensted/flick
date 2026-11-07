public struct ToolCall: Encodable, Equatable {
    public struct Function: Encodable, Equatable {
        public let name: String
        public let arguments: String
    }

    public let id: String
    let type = "function"
    public let function: Function

    public init(id: String, name: String, arguments: String) {
        self.id = id
        function = Function(name: name, arguments: arguments)
    }
}

public struct ToolResult: Equatable {
    public let callID: String
    public let output: String
    public let change: SettingsChange?
    public var isReverted = false

    public init(callID: String, output: String, change: SettingsChange? = nil) {
        self.callID = callID
        self.output = output
        self.change = change
    }

    var outputForModel: String {
        isReverted ? "\(output) \(ChatPrompt.revertedNote)" : output
    }
}

struct ModelMessage: Encodable, Equatable {
    enum Role: String, Encodable {
        case system, user, assistant, tool
    }

    let role: Role
    let content: String?
    var toolCalls: [ToolCall]?
    var toolCallID: String?

    static func system(_ text: String) -> ModelMessage {
        ModelMessage(role: .system, content: text)
    }

    static func tool(_ result: ToolResult) -> ModelMessage {
        ModelMessage(role: .tool, content: result.outputForModel, toolCallID: result.callID)
    }

    private enum CodingKeys: String, CodingKey {
        case role, content
        case toolCalls = "tool_calls"
        case toolCallID = "tool_call_id"
    }
}
