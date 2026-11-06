import Foundation
import Testing
@testable import FlickCore

struct TranslateTests {
    let languages = TranslateLanguages(preferred: ["en-DK", "da-DK"])
    let hello = Translation(original: "hello", text: "hej", source: "en", target: "da")

    @Test func automaticTargetSwitchesAwayFromPrimaryLanguage() {
        #expect(TranslatePair().firstTarget(languages) == "en")
        #expect(TranslatePair().retarget(detected: "en", languages) == "da")
        #expect(TranslatePair().retarget(detected: "fr", languages) == nil)
    }

    @Test func chosenTargetIsNeverRetargeted() {
        let pair = TranslatePair(target: "de")
        #expect(pair.firstTarget(languages) == "de")
        #expect(pair.retarget(detected: "en", languages) == nil)
    }

    @Test func swapUsesTheLastTranslation() {
        #expect(TranslatePair().swapped(after: hello) == TranslatePair(source: "da", target: "en"))
        #expect(TranslatePair(source: "fr", target: "de").swapped(after: nil) == TranslatePair(source: "de", target: "fr"))
    }

    @Test func translatesToSecondLanguageWhenSourceIsPrimary() {
        let languages = TranslateLanguages(preferred: ["en-DK", "da-DK"])
        #expect(languages.target(forSource: "en") == "da")
        #expect(languages.target(forSource: "fr") == "en")
    }

    @Test func picksAFallbackSecondLanguage() {
        #expect(TranslateLanguages(preferred: ["en-US"]).secondary == "es")
        #expect(TranslateLanguages(preferred: ["da-DK", "da"]).secondary == "en")
    }

    @Test func parsesGoogleResponse() throws {
        let json = #"[[["Hej verden. ","Hello world. ",null,null,3],["Hvordan har du det?","How are you?",null,null,3]],null,"en",null]"#
        let result = try GoogleTranslate.parse(Data(json.utf8))
        #expect(result == GoogleTranslate.Result(text: "Hej verden. Hvordan har du det?", source: "en"))
    }

    @Test func rejectsUnexpectedResponse() {
        #expect(throws: (any Error).self) { try GoogleTranslate.parse(Data("{}".utf8)) }
    }

    @Test func doneStateShowsTranslationThenWebLink() {
        let translation = Translation(original: "hello", text: "hej", source: "en", target: "da")
        let ids = GoogleTranslate.results(for: .done(translation), text: "hello", pair: TranslatePair(),
                                          languages: languages, locale: Locale(identifier: "en")).map(\.id)
        #expect(ids == ["translation", "url"])
    }
}
