import Testing
@testable import FlickCore

struct FeedbackTests {
    @Test func confirmsCopies() {
        #expect(Feedback.after(.command(.loremParagraph), delivered: .copy) == .copied)
        #expect(Feedback.after(.emoji(Emoji(character: "🎉", name: "party popper")), delivered: .copy) == .copied)
    }

    @Test func staysQuietWhenPasting() {
        #expect(Feedback.after(.command(.loremSentence), delivered: .paste) == nil)
    }

    @Test func confirmsKeepAwake() {
        #expect(Feedback.after(.command(.keepAwake), delivered: nil)?.text == "Your Mac will stay awake")
        #expect(Feedback.after(.command(.keepAwakeFor(minutes: 90)), delivered: nil)?.text == "Your Mac will stay awake for 1 h 30 min")
        #expect(Feedback.after(.command(.allowSleep), delivered: nil) == .sleepAllowed)
    }

    @Test func nothingForOpeningThings() {
        #expect(Feedback.after(.google("x"), delivered: nil) == nil)
    }
}
