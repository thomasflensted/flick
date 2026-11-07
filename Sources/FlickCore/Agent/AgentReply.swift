import Foundation

public struct OpenRouterError: LocalizedError, Equatable {
    public let errorDescription: String?
}

public enum AgentReply {
    private struct Response: Decodable {
        struct Choice: Decodable {
            let message: AgentMessage
        }
        let choices: [Choice]?
        let error: StreamLine.APIError?
    }

    public static func message(fromJSON data: Data) throws -> AgentMessage {
        let response = try JSONDecoder().decode(Response.self, from: data)
        if let error = response.error { throw OpenRouterError(errorDescription: error.message) }
        guard let message = response.choices?.first?.message else { throw OpenRouterError(errorDescription: "OpenRouter sent an empty reply.") }
        return message
    }
}
