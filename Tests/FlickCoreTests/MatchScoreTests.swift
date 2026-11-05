import Testing
@testable import FlickCore

struct MatchScoreTests {
    @Test(arguments: [
        ("slack", "Slack", MatchScore.exact),
        ("sl", "Slack", MatchScore.prefix),
        ("render", "Flokk: Render", MatchScore.wordPrefix),
        ("vsc", "Visual Studio Code", MatchScore.initials),
        ("ack", "Slack", MatchScore.substring),
        ("ghty", "Ghostty", MatchScore.subsequence),
    ])
    func tiers(query: String, target: String, expected: Int) {
        #expect(MatchScore.score(query, against: target) == expected)
    }

    @Test func noMatch() {
        #expect(MatchScore.score("xyz", against: "Slack") == nil)
    }

    @Test func emptyQueryMatchesEverything() {
        #expect(MatchScore.score("", against: "Slack") == 0)
    }
}
