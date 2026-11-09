import FlickCore
import Foundation

final class TranslateSource: ModeSource {
    var onUpdate: () -> Void {
        get { translator.onUpdate }
        set { translator.onUpdate = newValue }
    }
    private let translator: Translator

    init(translator: Translator) {
        self.translator = translator
    }

    func enter() {
        translator.translate("")
    }

    func queryChanged(_ query: String) {
        translator.translate(query)
    }

    func results(for query: String) -> [ResultItem] {
        GoogleTranslate.results(for: translator.state, text: query, pair: translator.pair, languages: translator.languages, locale: .current)
    }
}
