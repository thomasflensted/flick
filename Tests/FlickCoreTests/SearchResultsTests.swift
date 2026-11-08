import Foundation
import Testing
@testable import FlickCore

struct SearchResultsTests {
    let google = Quicklink(name: "Search Google", link: "https://google.com/search?q={argument}", keyword: "g")
    let render = Quicklink(name: "Flokk: Render", link: "https://dashboard.render.com")
    let slack = AppEntry(name: "Slack", path: "/Applications/Slack.app")
    let safari = AppEntry(name: "Safari", path: "/Applications/Safari.app")

    func search(_ query: String, usage: [String: Int] = [:]) -> [ResultItem] {
        SearchResults(links: [google, render], apps: [slack, safari], usage: usage).results(for: query)
    }

    @Test func typedArgumentRunsTheQuicklink() {
        #expect(search("g pasta").first?.kind == .quicklink(google, argument: "pasta"))
    }

    @Test func exactKeywordRanksFirst() {
        #expect(search("g").first?.kind == .quicklink(google, argument: nil))
    }

    @Test func quicklinksBeatAppsOnEqualMatch() {
        let links = [Quicklink(name: "Slack status", link: "https://status.slack.com")]
        let results = SearchResults(links: links, apps: [slack], usage: [:]).results(for: "sla")
        #expect(results.first?.title == "Slack status")
    }

    @Test func modesBeatAppsOnEqualMatch() {
        let weatherApp = AppEntry(name: "Weather", path: "/System/Applications/Weather.app")
        let results = SearchResults(links: [], apps: [weatherApp], usage: [:])
        #expect(results.results(for: "weather").first?.kind == .mode(.weather))
        #expect(results.results(for: "weath").first?.kind == .mode(.weather))
    }

    @Test func usageLiftsResults() {
        let results = search("s", usage: [UsageKey.app(safari): 20])
        #expect(results.first?.kind == .app(safari))
    }

    @Test func alwaysEndsWithGoogleThenAskAI() {
        let kinds = search("anything at all").suffix(2).map(\.kind)
        #expect(kinds == [.google("anything at all"), .askAI("anything at all")])
    }

    @Test func offersToOpenWebAddresses() {
        #expect(search("reddit.com").contains { $0.id == "url" })
    }

    @Test func emptyQueryShowsMostUsed() {
        let results = search("", usage: [UsageKey.app(slack): 3, UsageKey.quicklink(render): 9])
        #expect(results.map(\.title) == ["Flokk: Render", "Slack"])
    }

    @Test func emptyQueryWithoutUsageShowsQuicklinks() {
        #expect(search("").map(\.title) == ["Search Google", "Flokk: Render"])
    }

    @Test func usageBoostIsCapped() {
        #expect(SearchResults.usageBoost(1000) == SearchResults.usageBoost(20))
    }

    @Test func findsLinkTriggeredByKeywordOrName() {
        let results = SearchResults(links: [google, render], apps: [], usage: [:])
        #expect(results.linkTriggered(by: "G") == google)
        #expect(results.linkTriggered(by: "search google") == google)
        #expect(results.linkTriggered(by: "flokk: render") == nil)
    }
}

struct CommandSearchTests {
    func search(_ query: String, keepingAwake: Bool = false) -> [ResultItem] {
        SearchResults(links: [], apps: [], usage: [:], commands: Command.available(isKeepingAwake: keepingAwake)).results(for: query)
    }

    @Test func offersKeepAwakeWhenOff() {
        #expect(search("awake").first?.kind == .command(.keepAwake))
    }

    @Test func oldNameStillFindsIt() {
        #expect(search("caf").first?.kind == .command(.keepAwake))
        #expect(search("decaf", keepingAwake: true).first?.kind == .command(.allowSleep))
    }

    @Test func offersAllowSleepWhenOn() {
        #expect(search("sleep", keepingAwake: true).first?.kind == .command(.allowSleep))
        #expect(!search("awake", keepingAwake: true).contains { $0.kind == .command(.keepAwake) })
    }

    @Test func timedKeepAwakeFromQuery() {
        #expect(search("awake 1h30").first?.kind == .command(.keepAwakeFor(minutes: 90)))
        #expect(search("keep awake 20").first?.title == "Keep Awake for 20 min")
        #expect(search("caf 45").first?.kind == .command(.keepAwakeFor(minutes: 45)))
    }

    @Test func findsWindowTiles() {
        #expect(search("left half").first?.kind == .command(.tile(.leftHalf)))
        #expect(search("maximize").first?.kind == .command(.tile(.maximize)))
        #expect(search("full screen").first?.kind == .command(.toggleFullScreen))
    }

    @Test func findsEmojiMode() {
        #expect(search("emoji").first?.kind == .mode(.emoji))
    }

    @Test func findsConnectedDrivesByEject() {
        #expect(search("eject").first?.kind == .mode(.drives))
    }

    @Test func noTimedKeepAwakeWithoutDuration() {
        #expect(SearchResults.keepAwakeMinutes(in: "awake later") == nil)
        #expect(SearchResults.keepAwakeMinutes(in: "aw 20") == nil)
    }
}
