import FlickCore
import Foundation

final class Suggester {
    var onUpdate: () -> Void = {}
    private var query = ""
    private var suggestions: [String] = []
    private var task: Task<Void, Never>?

    private static let debounce = Duration.milliseconds(250)

    func suggestions(for query: String) -> [String] {
        query.trimmingCharacters(in: .whitespaces) == self.query ? suggestions : []
    }

    func suggest(_ query: String) {
        task?.cancel()
        let text = query.trimmingCharacters(in: .whitespaces)
        task = Task { @MainActor in
            try? await Task.sleep(for: Self.debounce)
            guard !Task.isCancelled, let fetched = try? await fetch(text), !Task.isCancelled else { return }
            self.query = text
            suggestions = fetched
            onUpdate()
        }
    }

    func clear() {
        task?.cancel()
        query = ""
        suggestions = []
    }

    private func fetch(_ text: String) async throws -> [String] {
        let (data, _) = try await URLSession.shared.data(from: GoogleSuggest.requestURL(query: text))
        return try GoogleSuggest.parse(data, query: text)
    }
}
