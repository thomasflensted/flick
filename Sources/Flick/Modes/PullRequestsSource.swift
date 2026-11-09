import FlickCore

final class PullRequestsSource: ModeSource {
    var onUpdate: () -> Void = {}
    private(set) var isLoading = false
    private var pullRequests: PullRequestsState = .loading

    func enter() {
        isLoading = true
        Background.load(OpenPullRequests.fetch) { [weak self] in
            self?.pullRequests = $0
            self?.isLoading = false
            self?.onUpdate()
        }
    }

    func results(for query: String) -> [ResultItem] {
        PullRequests.results(for: query, in: pullRequests)
    }
}
