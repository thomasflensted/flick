import Testing
@testable import FlickCore

struct DeliveryTests {
    @Test func textResultsCanBeCopied() {
        #expect(ResultKind.command(.loremParagraph).producesText)
        #expect(ResultKind.emoji(Emoji(character: "🎉", name: "party popper")).producesText)
    }

    @Test func actionsDoNotProduceText() {
        #expect(!ResultKind.command(.keepAwake).producesText)
        #expect(!ResultKind.google("x").producesText)
        #expect(!ResultKind.mode(.emoji).producesText)
    }
}
