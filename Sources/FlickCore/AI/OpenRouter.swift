import Foundation

public enum OpenRouter {
    public static let chatURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    public static let modelsURL = URL(string: "https://openrouter.ai/api/v1/models")!
    public static let keysPage = URL(string: "https://openrouter.ai/settings/keys")!

    private struct Reasoning: Encodable {
        let enabled = false
    }

    private struct ChatBody: Encodable {
        let model: String
        let messages: [ModelMessage]
        let stream = true
        let reasoning = Reasoning()
        let modalities: [String]?
        let tools: [ToolDefinition]?
    }

    public static func chatBody(model: AIModel, messages: [ChatMessage]) throws -> Data {
        let tools = model.supportsTools ? ToolDefinition.all : nil
        let body = ChatBody(model: model.id, messages: modelMessages(messages, withTools: tools != nil),
                            modalities: modalities(for: model), tools: tools)
        return try JSONEncoder().encode(body)
    }

    static func modelMessages(_ messages: [ChatMessage], withTools: Bool) -> [ModelMessage] {
        let system = ModelMessage.system(withTools ? ChatPrompt.settings : ChatPrompt.withoutTools)
        return [system] + messages.flatMap(\.modelMessages)
    }

    static func modalities(for model: AIModel) -> [String]? {
        model.outputsImages ? ["image", "text"] : nil
    }

    public static func chatRequest(key: String, model: AIModel, messages: [ChatMessage]) throws -> URLRequest {
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Flick", forHTTPHeaderField: "X-Title")
        request.httpBody = try chatBody(model: model, messages: messages)
        return request
    }
}
