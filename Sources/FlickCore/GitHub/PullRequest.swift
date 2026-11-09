import Foundation

public struct PullRequest: Hashable, Decodable {
    public struct Repository: Hashable, Decodable {
        public let nameWithOwner: String
    }

    public let number: Int
    public let title: String
    public let url: URL
    public let repository: Repository
    public let isDraft: Bool

    public init(number: Int, title: String, url: URL, repository: String, isDraft: Bool) {
        self.number = number
        self.title = title
        self.url = url
        self.repository = Repository(nameWithOwner: repository)
        self.isDraft = isDraft
    }

    var details: String {
        ["\(repository.nameWithOwner) #\(number)", isDraft ? "Draft" : nil].compactMap { $0 }.joined(separator: " · ")
    }
}

public enum PullRequestsState: Equatable {
    case loading
    case loaded([PullRequest])
    case failed(String)
}

public enum PullRequests {
    public static let ghArguments = ["search", "prs", "--author=@me", "--state=open", "--sort=updated",
                                     "--json=number,title,url,repository,isDraft"]

    public static func decode(_ data: Data) -> [PullRequest]? {
        try? JSONDecoder().decode([PullRequest].self, from: data)
    }

    public static func results(for query: String, in state: PullRequestsState) -> [ResultItem] {
        switch state {
        case .loading: return [.hint("Loading pull requests…")]
        case .failed(let reason): return [.hint(reason)]
        case .loaded(let pullRequests) where pullRequests.isEmpty: return [.hint("No open pull requests")]
        case .loaded(let pullRequests):
            return Ranker(usage: [:])
                .rank(pullRequests, query: query, texts: { [$0.title, $0.repository.nameWithOwner, String($0.number)] },
                      key: ResultItem.pullRequestID)
                .map(ResultItem.pullRequest)
        }
    }
}
