import Testing
@testable import FlickCore

struct EmojiTests {
    @Test func catalogHasCommonEmoji() {
        let characters = Set(EmojiCatalog.all.map(\.character))
        #expect(characters.isSuperset(of: ["😀", "😂", "👍", "🎉", "❤\u{FE0F}", "☀\u{FE0F}"]))
    }

    @Test func startsWithSmileys() {
        #expect(EmojiCatalog.all.first?.character == "😀")
    }

    @Test func listsEachEmojiOnce() {
        #expect(Set(EmojiCatalog.all.map(\.character)).count == EmojiCatalog.all.count)
    }

    @Test func excludesModifiersAndRegionalIndicators() {
        let characters = Set(EmojiCatalog.all.map(\.character))
        #expect(!characters.contains("🏻"))
        #expect(!characters.contains("🇩"))
    }

    @Test func searchesByName() {
        #expect(EmojiCatalog.results(for: "tears of joy", usage: [:]).first?.title == "Face With Tears Of Joy")
    }

    @Test func frequentlyUsedComesFirst() {
        let usage = [UsageKey.emoji(Emoji(character: "🎉", name: "party popper")): 5]
        #expect(EmojiCatalog.results(for: "", usage: usage).first?.kind == .emoji(Emoji(character: "🎉", name: "party popper")))
    }
}

struct RankerTests {
    @Test func keepsOriginalOrderForEqualScores() {
        let ranked = Ranker(usage: [:]).rank(["banana", "apple", "cherry"], query: "", text: { $0 }, key: { $0 })
        #expect(ranked == ["banana", "apple", "cherry"])
    }

    @Test func dropsNonMatches() {
        #expect(Ranker(usage: [:]).rank(["banana", "apple"], query: "app", text: { $0 }, key: { $0 }) == ["apple"])
    }
}
