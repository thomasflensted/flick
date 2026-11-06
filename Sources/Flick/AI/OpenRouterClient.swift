import FlickCore
import Foundation

enum OpenRouterClient {
    struct Failure: LocalizedError {
        let errorDescription: String?
    }

    static func stream(key: String, model: AIModel, messages: [ChatMessage]) -> AsyncThrowingStream<AnswerPart, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try OpenRouter.chatRequest(key: key, model: model, messages: messages)
                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in bytes.lines {
                        for event in StreamLine.parse(line) {
                            switch event {
                            case .answer(let part): continuation.yield(part)
                            case .failed(let message): throw Failure(errorDescription: message)
                            case .done: continuation.finish(); return
                            }
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
