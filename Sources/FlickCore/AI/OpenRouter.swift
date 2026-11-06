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
        let messages: [ChatMessage]
        let stream = true
        let reasoning = Reasoning()
        let modalities: [String]?
    }

    public static func chatBody(model: AIModel, messages: [ChatMessage]) throws -> Data {
        try JSONEncoder().encode(ChatBody(model: model.id, messages: messages, modalities: modalities(for: model)))
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
