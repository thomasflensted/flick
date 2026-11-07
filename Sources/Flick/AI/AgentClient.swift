import FlickCore
import Foundation

enum AgentClient {
    static func send(key: String, model: AIModel, messages: [AgentMessage]) async throws -> AgentMessage {
        let request = try OpenRouter.agentRequest(key: key, model: model, messages: messages)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try AgentReply.message(fromJSON: data)
    }
}
