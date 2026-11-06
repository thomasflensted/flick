import Foundation

public struct TranslatePair: Codable, Equatable {
    public var source: String?
    public var target: String?

    public init(source: String? = nil, target: String? = nil) {
        self.source = source
        self.target = target
    }

    public func firstTarget(_ languages: TranslateLanguages) -> String {
        target ?? languages.primary
    }

    public func retarget(detected: String, _ languages: TranslateLanguages) -> String? {
        guard target == nil, detected == languages.primary else { return nil }
        return languages.target(forSource: detected)
    }

    public func swapped(after translation: Translation?) -> TranslatePair {
        TranslatePair(source: translation?.target ?? target, target: translation?.source ?? source)
    }
}
