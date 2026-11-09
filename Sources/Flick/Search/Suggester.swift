import FlickCore
import Foundation

final class Suggester: Suggesting {
    var onUpdate: () -> Void = {}
    private(set) var suggestions: [String] = []
    private let debouncer = Debouncer(delay: .milliseconds(250))

    func suggest(_ query: String) {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { clear(); return }
        debouncer.run { [weak self] in
            guard let fetched = try? await Self.fetch(text), !Task.isCancelled else { return }
            self?.suggestions = fetched
            self?.onUpdate()
        }
    }

    func clear() {
        debouncer.cancel()
        suggestions = []
    }

    private static func fetch(_ text: String) async throws -> [String] {
        let (data, _) = try await URLSession.shared.data(from: GoogleSuggest.requestURL(query: text))
        return try GoogleSuggest.parse(data, query: text)
    }
}
