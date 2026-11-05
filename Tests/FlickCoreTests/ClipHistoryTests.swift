import Foundation
import Testing
@testable import FlickCore

struct ClipHistoryTests {
    let now = Date(timeIntervalSince1970: 1_000_000)

    func entry(_ text: String, secondsAgo: TimeInterval = 0) -> ClipEntry {
        ClipEntry(text: text, copiedAt: now.addingTimeInterval(-secondsAgo))
    }

    @Test func newestComesFirst() {
        let history = ClipHistory.adding(entry("b"), to: [entry("a")])
        #expect(history.map(\.text) == ["b", "a"])
    }

    @Test func copyingAgainMovesToTop() {
        let history = ClipHistory.adding(entry("a"), to: [entry("b"), entry("a")])
        #expect(history.map(\.text) == ["a", "b"])
    }

    @Test func ignoresBlankText() {
        #expect(ClipHistory.adding(entry("  \n"), to: [entry("a")]).map(\.text) == ["a"])
    }

    @Test func keepsAtMostTheLimit() {
        let full = (0..<ClipHistory.limit).map { entry("\($0)") }
        let history = ClipHistory.adding(entry("new"), to: full)
        #expect(history.count == ClipHistory.limit)
        #expect(history.first?.text == "new")
    }

    @Test func skipsPasswordsAndTransientCopies() {
        #expect(!ClipHistory.shouldRecord(types: ["public.utf8-plain-text", "org.nspasteboard.ConcealedType"]))
        #expect(!ClipHistory.shouldRecord(types: ["public.utf8-plain-text", "com.agilebits.onepassword"]))
        #expect(ClipHistory.shouldRecord(types: ["public.utf8-plain-text"]))
    }

    @Test func searchMatchesTextCaseInsensitively() {
        let results = ClipHistory.results(for: "HELLO", in: [entry("say hello"), entry("bye")], now: now)
        #expect(results.map(\.title) == ["say hello"])
    }

    @Test(arguments: [(10.0, "Just now"), (300.0, "5 min ago"), (7200.0, "2 h ago"), (90_000.0, "Yesterday"), (300_000.0, "3 days ago")])
    func ages(secondsAgo: Double, text: String) {
        #expect(ClipHistory.age(of: now.addingTimeInterval(-secondsAgo), now: now) == text)
    }

    @Test func titleIsFirstLine() {
        #expect(ClipHistory.title(of: "  first line  \nsecond") == "first line")
    }

    @Test func subtitleShowsAppAndAge() {
        let clip = ClipEntry(text: "x", copiedAt: now.addingTimeInterval(-120), appName: "Safari")
        #expect(ResultItem.clip(clip, now: now).subtitle == "Safari · 2 min ago")
    }
}
