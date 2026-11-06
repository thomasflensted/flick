import FlickCore
import Foundation

enum OpenRouterClient {
    struct Failure: LocalizedError {
        let errorDescription: String?
    }

    static func stream(key: String, model: AIModel, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try OpenRouter.chatRequest(key: key, model: model, messages: messages)
                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in bytes.lines {
                        switch StreamLine.parse(line) {
                        case .text(let text): continuation.yield(text)
                        case .failed(let message): throw Failure(errorDescription: message)
                        case .done: continuation.finish(); return
                        case nil: continue
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
