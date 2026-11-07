import Foundation

public struct ChatMessage: Equatable, Identifiable {
    public enum Role {
        case user, assistant
    }

    public let id: Int
    public let role: Role
    public var content: String
    public var images: [Data] = []
    public var toolCalls: [ToolCall] = []
    public var toolResults: [ToolResult] = []

    public init(id: Int, role: Role, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }

    static let imagePlaceholder = "[image]"

    public var isEmpty: Bool { !hasAnswer && !hasChanges }

    public var hasAnswer: Bool { !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !images.isEmpty }

    public var hasChanges: Bool { toolResults.contains { $0.change != nil } }

    var contentForModel: String? {
        guard content.isEmpty else { return content }
        if !images.isEmpty { return Self.imagePlaceholder }
        return toolCalls.isEmpty ? content : nil
    }

    var modelMessages: [ModelMessage] {
        let message = ModelMessage(role: role == .user ? .user : .assistant, content: contentForModel,
                                   toolCalls: toolCalls.isEmpty ? nil : toolCalls)
        return [message] + toolResults.map(ModelMessage.tool)
    }

    public mutating func append(_ part: AnswerPart) {
        switch part {
        case .text(let text): content += text
        case .image(let data): images.append(data)
        }
    }
}
