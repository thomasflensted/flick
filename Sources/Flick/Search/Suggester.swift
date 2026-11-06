import FlickCore
import Foundation

final class Suggester {
    var onUpdate: () -> Void = {}
    private(set) var suggestions: [String] = []
    private var task: Task<Void, Never>?

    private static let debounce = Duration.milliseconds(250)

    func suggest(_ query: String) {
        task?.cancel()
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { clear(); return }
        task = Task { @MainActor in
            try? await Task.sleep(for: Self.debounce)
            guard !Task.isCancelled, let fetched = try? await fetch(text), !Task.isCancelled else { return }
            suggestions = fetched
            onUpdate()
        }
    }

    func clear() {
        task?.cancel()
        suggestions = []
    }

    private func fetch(_ text: String) async throws -> [String] {
        let (data, _) = try await URLSession.shared.data(from: GoogleSuggest.requestURL(query: text))
        return try GoogleSuggest.parse(data, query: text)
    }
}
