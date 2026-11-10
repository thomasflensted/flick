import Foundation
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

    @Test func pullRequestsHaveACopyableLink() {
        let url = URL(string: "https://github.com/o/r/pull/1")!
        let pullRequest = PullRequest(number: 1, title: "Fix", url: url, repository: "o/r", isDraft: false)
        #expect(ResultKind.pullRequest(pullRequest).link == url)
        #expect(!ResultKind.pullRequest(pullRequest).producesText)
    }
}
