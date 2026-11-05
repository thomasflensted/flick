import Foundation

public enum StreamEvent: Equatable {
    case text(String)
    case failed(String)
    case done
}

public enum StreamLine {
    private struct Chunk: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable { let content: String? }
            let delta: Delta?
        }
        let choices: [Choice]?
        let error: APIError?
    }

    private struct ErrorBody: Decodable {
        let error: APIError
    }

    struct APIError: Decodable {
        let message: String
    }

    private static let dataPrefix = "data: "
    private static let doneMarker = "[DONE]"

    public static func parse(_ line: String) -> StreamEvent? {
        if line.hasPrefix(dataPrefix) { return parseData(String(line.dropFirst(dataPrefix.count))) }
        if line.hasPrefix("{"), let body = decode(ErrorBody.self, line) { return .failed(body.error.message) }
        return nil
    }

    private static func parseData(_ payload: String) -> StreamEvent? {
        if payload == doneMarker { return .done }
        guard let chunk = decode(Chunk.self, payload) else { return nil }
        if let error = chunk.error { return .failed(error.message) }
        guard let text = chunk.choices?.first?.delta?.content, !text.isEmpty else { return nil }
        return .text(text)
    }

    private static func decode<T: Decodable>(_ type: T.Type, _ text: String) -> T? {
        try? JSONDecoder().decode(type, from: Data(text.utf8))
    }
}
