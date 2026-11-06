import Foundation

public enum StreamEvent: Equatable {
    case answer(AnswerPart)
    case failed(String)
    case done
}

public enum StreamLine {
    private struct Chunk: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable {
                let content: String?
                let images: [Image]?
            }
            let delta: Delta?
        }
        let choices: [Choice]?
        let error: APIError?
    }

    private struct Image: Decodable {
        struct ImageURL: Decodable { let url: String }
        let image_url: ImageURL
    }

    private struct ErrorBody: Decodable {
        let error: APIError
    }

    struct APIError: Decodable {
        let message: String
    }

    private static let dataPrefix = "data: "
    private static let doneMarker = "[DONE]"
    private static let base64Marker = ";base64,"

    public static func parse(_ line: String) -> [StreamEvent] {
        if line.hasPrefix(dataPrefix) { return parseData(String(line.dropFirst(dataPrefix.count))) }
        if line.hasPrefix("{"), let body = decode(ErrorBody.self, line) { return [.failed(body.error.message)] }
        return []
    }

    private static func parseData(_ payload: String) -> [StreamEvent] {
        if payload == doneMarker { return [.done] }
        guard let chunk = decode(Chunk.self, payload) else { return [] }
        if let error = chunk.error { return [.failed(error.message)] }
        guard let delta = chunk.choices?.first?.delta else { return [] }
        let text = [delta.content].compactMap { $0 }.filter { !$0.isEmpty }.map { StreamEvent.answer(.text($0)) }
        let images = (delta.images ?? []).compactMap { imageData(fromDataURL: $0.image_url.url) }.map { StreamEvent.answer(.image($0)) }
        return text + images
    }

    static func imageData(fromDataURL url: String) -> Data? {
        guard let marker = url.range(of: base64Marker) else { return nil }
        return Data(base64Encoded: String(url[marker.upperBound...]))
    }

    private static func decode<T: Decodable>(_ type: T.Type, _ text: String) -> T? {
        try? JSONDecoder().decode(type, from: Data(text.utf8))
    }
}
