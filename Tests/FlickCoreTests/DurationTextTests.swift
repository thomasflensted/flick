import Testing
@testable import FlickCore

struct DurationTextTests {
    @Test(arguments: [("30", 30), ("30m", 30), ("2h", 120), ("1h30m", 90), ("1h 30", 90), ("1 H", 60)])
    func parses(text: String, minutes: Int) {
        #expect(DurationText.minutes(from: text) == minutes)
    }

    @Test(arguments: ["", "abc", "0", "h", "30s"])
    func rejects(text: String) {
        #expect(DurationText.minutes(from: text) == nil)
    }

    @Test(arguments: [(45, "45 min"), (60, "1 h"), (90, "1 h 30 min")])
    func formats(minutes: Int, text: String) {
        #expect(DurationText.format(minutes: minutes) == text)
    }
}
