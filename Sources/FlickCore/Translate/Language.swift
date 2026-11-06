import Foundation

public enum Language {
    public static func choices(in locale: Locale) -> [String] {
        ["ar", "zh-CN", "cs", "da", "nl", "en", "fi", "fr", "de", "el", "hi", "it", "ja", "ko", "no", "pl", "pt", "ru",
         "es", "sv", "th", "tr", "uk", "vi"]
            .sorted { name(of: $0, in: locale) < name(of: $1, in: locale) }
    }

    public static func name(of code: String, in locale: Locale) -> String {
        locale.localizedString(forIdentifier: code) ?? code
    }

    public static func codes(fromPreferred identifiers: [String]) -> [String] {
        var seen = Set<String>()
        return identifiers.compactMap { Locale(identifier: $0).language.languageCode?.identifier }
            .filter { seen.insert($0).inserted }
    }
}

public struct TranslateLanguages: Equatable {
    public let primary: String
    public let secondary: String

    public init(preferred identifiers: [String]) {
        let codes = Language.codes(fromPreferred: identifiers)
        primary = codes.first ?? "en"
        secondary = codes.dropFirst().first ?? (primary == "en" ? "es" : "en")
    }

    public func target(forSource source: String) -> String {
        source == primary ? secondary : primary
    }
}
