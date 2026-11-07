import Foundation

public struct AgentToolCall: Codable, Equatable {
    public struct Function: Codable, Equatable {
        public let name: String
        public let arguments: String
    }

    public let id: String
    public let type: String
    public let function: Function

    public init(id: String, name: String, arguments: String) {
        self.id = id
        type = "function"
        function = Function(name: name, arguments: arguments)
    }
}

public struct AgentMessage: Codable, Equatable {
    public enum Role: String, Codable {
        case system, user, assistant, tool
    }

    public let role: Role
    public let content: String?
    public var toolCalls: [AgentToolCall]?
    public var toolCallID: String?

    public init(role: Role, content: String?, toolCalls: [AgentToolCall]? = nil, toolCallID: String? = nil) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
    }

    public static func user(_ text: String) -> AgentMessage {
        AgentMessage(role: .user, content: text)
    }

    public static func tool(callID: String, output: String) -> AgentMessage {
        AgentMessage(role: .tool, content: output, toolCallID: callID)
    }

    public var calls: [AgentToolCall] { toolCalls ?? [] }

    public var text: String? {
        let text = content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }

    private enum CodingKeys: String, CodingKey {
        case role, content
        case toolCalls = "tool_calls"
        case toolCallID = "tool_call_id"
    }
}
