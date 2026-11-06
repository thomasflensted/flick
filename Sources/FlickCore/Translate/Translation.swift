import Foundation

public struct Translation: Equatable {
    public let original: String
    public let text: String
    public let source: String
    public let target: String

    public init(original: String, text: String, source: String, target: String) {
        self.original = original
        self.text = text
        self.source = source
        self.target = target
    }

    public func languages(_ locale: Locale) -> String {
        "\(Language.name(of: source, in: locale)) → \(Language.name(of: target, in: locale))"
    }
}

public enum TranslationState: Equatable {
    case idle
    case loading
    case done(Translation)
    case failed(String)
}

public enum GoogleTranslate {
    public struct Result: Equatable {
        public let text: String
        public let source: String
    }

    struct Malformed: Error {}

    public static func requestURL(text: String, source: String?, target: String) -> URL {
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")!
        components.queryItems = [.init(name: "client", value: "gtx"), .init(name: "sl", value: source ?? "auto"),
                                 .init(name: "tl", value: target), .init(name: "dt", value: "t"), .init(name: "q", value: text)]
        return components.url!
    }

    public static func webURL(text: String, source: String?, target: String) -> URL {
        var components = URLComponents(string: "https://translate.google.com/")!
        components.queryItems = [.init(name: "sl", value: source ?? "auto"), .init(name: "tl", value: target),
                                 .init(name: "text", value: text), .init(name: "op", value: "translate")]
        return components.url!
    }

    public static func parse(_ data: Data) throws -> Result {
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        guard let segments = json[0]?.array, let source = json[2]?.string else { throw Malformed() }
        return Result(text: segments.compactMap { $0[0]?.string }.joined(), source: source)
    }

    public static func results(for state: TranslationState, text: String, pair: TranslatePair,
                               languages: TranslateLanguages, locale: Locale) -> [ResultItem] {
        let open = ResultItem.openGoogleTranslate(webURL(text: text, source: pair.source, target: pair.firstTarget(languages)))
        switch state {
        case .idle: return [.hint("Type text to translate. Pick languages above, or press ⌘S to swap them.")]
        case .loading: return [.hint("Translating…"), open]
        case .done(let translation):
            let url = webURL(text: translation.original, source: translation.source, target: translation.target)
            return [.translation(translation, locale: locale), .openGoogleTranslate(url)]
        case .failed(let message): return [.hint(message), open]
        }
    }
}
