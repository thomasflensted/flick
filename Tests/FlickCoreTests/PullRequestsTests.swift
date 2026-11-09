import Foundation
import Testing
@testable import FlickCore

struct PullRequestsTests {
    private let api = PullRequest(number: 658, title: "Store a timezone on every event",
                                  url: URL(string: "https://github.com/joinflokk/api/pull/658")!,
                                  repository: "joinflokk/api", isDraft: false)
    private let app = PullRequest(number: 12, title: "Release flow", url: URL(string: "https://github.com/me/app/pull/12")!,
                                  repository: "me/app", isDraft: true)

    @Test func decodesGhSearchOutput() {
        let json = """
        [{"isDraft":false,"number":658,"repository":{"name":"api","nameWithOwner":"joinflokk/api"},\
        "title":"Store a timezone on every event","url":"https://github.com/joinflokk/api/pull/658"}]
        """
        #expect(PullRequests.decode(Data(json.utf8)) == [api])
    }

    @Test func rejectsOutputThatIsNotAList() {
        #expect(PullRequests.decode(Data("gh: not logged in".utf8)) == nil)
    }

    @Test func showsRepositoryNumberAndDraft() {
        #expect(api.details == "joinflokk/api #658")
        #expect(app.details == "me/app #12 · Draft")
    }

    @Test func filtersByTitleOrRepository() {
        #expect(PullRequests.results(for: "timezone", in: .loaded([api, app])).map(\.title) == [api.title])
        #expect(PullRequests.results(for: "me/app", in: .loaded([api, app])).map(\.title) == [app.title])
    }

    @Test func hintsWhileLoadingWhenEmptyAndOnFailure() {
        #expect(PullRequests.results(for: "", in: .loading) == [.hint("Loading pull requests…")])
        #expect(PullRequests.results(for: "", in: .loaded([])) == [.hint("No open pull requests")])
        #expect(PullRequests.results(for: "", in: .failed("gh missing")) == [.hint("gh missing")])
    }
}
