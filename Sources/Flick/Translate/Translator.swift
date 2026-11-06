import FlickCore
import Foundation

final class Translator: ObservableObject {
    @Published private(set) var state: TranslationState = .idle
    @Published var pair: TranslatePair { didSet { savePair() } }
    var onUpdate: () -> Void = {}
    let languages = TranslateLanguages(preferred: Locale.preferredLanguages)
    private var task: Task<Void, Never>?

    private static let debounce = Duration.milliseconds(300)
    private static let pairKey = "translatePair"

    init() {
        let saved = UserDefaults.standard.data(forKey: Self.pairKey).flatMap { try? JSONDecoder().decode(TranslatePair.self, from: $0) }
        pair = saved ?? TranslatePair()
    }

    var translation: Translation? {
        if case .done(let translation) = state { return translation }
        return nil
    }

    func swap() {
        pair = pair.swapped(after: translation)
    }

    func translate(_ query: String) {
        task?.cancel()
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { update(.idle); return }
        if translation == nil { update(.loading) }
        let pair = pair
        task = Task { @MainActor in
            try? await Task.sleep(for: Self.debounce)
            if Task.isCancelled { return }
            let result: TranslationState
            do {
                result = .done(try await translation(of: text, pair: pair))
            } catch {
                result = .failed("Couldn't reach Google Translate. Check your connection.")
            }
            if !Task.isCancelled { update(result) }
        }
    }

    private func translation(of text: String, pair: TranslatePair) async throws -> Translation {
        var target = pair.firstTarget(languages)
        var result = try await fetch(text, source: pair.source, target: target)
        if let retarget = pair.retarget(detected: result.source, languages) {
            target = retarget
            result = try await fetch(text, source: pair.source, target: target)
        }
        return Translation(original: text, text: result.text, source: result.source, target: target)
    }

    private func fetch(_ text: String, source: String?, target: String) async throws -> GoogleTranslate.Result {
        let url = GoogleTranslate.requestURL(text: text, source: source, target: target)
        let (data, _) = try await URLSession.shared.data(from: url)
        return try GoogleTranslate.parse(data)
    }

    private func update(_ state: TranslationState) {
        self.state = state
        onUpdate()
    }

    private func savePair() {
        if let data = try? JSONEncoder().encode(pair) { UserDefaults.standard.set(data, forKey: Self.pairKey) }
    }
}
