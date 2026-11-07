import Foundation
import Testing
@testable import FlickCore

struct TimeZoneTests {
    let copenhagen = TimeZone(identifier: "Europe/Copenhagen")!
    let noonUTC = Date(timeIntervalSince1970: 1_762_516_800)
    let english = Locale(identifier: "en_GB")

    func answer(_ query: String) -> ZoneTime? {
        ZoneTime.answer(for: query, now: noonUTC, local: copenhagen)
    }

    @Test func findsPlacesByCityAndAbbreviation() {
        #expect(Place.find("new york")?.timeZone.identifier == "America/New_York")
        #expect(Place.find("Tokyo")?.name == "Tokyo")
        #expect(Place.find("pst")?.name == "PST")
        #expect(Place.find("utc") != nil)
        #expect(Place.find("apples") == nil)
    }

    @Test func parsesCurrentTimeQueries() {
        #expect(TimeQuery.parse("time in tokyo")?.to?.name == "Tokyo")
        #expect(TimeQuery.parse("new york time")?.to?.name == "New York")
        #expect(TimeQuery.parse("time in tokyo")?.time == nil)
    }

    @Test func parsesClockTimes() {
        #expect(TimeQuery.parse("3pm pst to cet") == TimeQuery(time: ClockTime(hour: 15, minute: 0), from: Place.find("pst"), to: Place.find("cet")))
        #expect(TimeQuery.parse("15:30 tokyo") == TimeQuery(time: ClockTime(hour: 15, minute: 30), from: Place.find("tokyo"), to: nil))
        #expect(TimeQuery.parse("9 am in new york") == TimeQuery(time: ClockTime(hour: 9, minute: 0), from: nil, to: Place.find("new york")))
        #expect(TimeQuery.parse("12am london")?.time == ClockTime(hour: 0, minute: 0))
    }

    @Test func ignoresNonTimes() {
        #expect(TimeQuery.parse("3pm") == nil)
        #expect(TimeQuery.parse("10 eur") == nil)
        #expect(TimeQuery.parse("3pm apples") == nil)
        #expect(TimeQuery.parse("25:00 tokyo") == nil)
        #expect(TimeQuery.parse("screen time") == nil)
        #expect(TimeQuery.parse("time machine") == nil)
    }

    @Test func convertsBetweenZones() throws {
        let time = try #require(answer("3pm london to tokyo"))
        #expect(time.time(english) == "00:00")
        #expect(time.summary(english) == "Sat 8 Nov · 9 h ahead of London")
    }

    @Test func convertsToLocalByDefault() throws {
        let time = try #require(answer("9am new york"))
        #expect(time.title(english) == "15:00 in Copenhagen")
        #expect(time.offsetText == "6 h ahead of New York")
    }

    @Test func showsCurrentTimeRelativeToLocal() throws {
        let time = try #require(answer("time in calcutta"))
        #expect(time.time(english) == "17:30")
        #expect(time.offsetText == "4 h 30 min ahead of Copenhagen")
    }

    @Test func worldClockFindsCitiesByPrefix() {
        let results = WorldClock.results(for: "tok", now: noonUTC, local: copenhagen, locale: english)
        #expect(results.first?.title == "21:00 in Tokyo")
    }

    @Test func worldClockAsksForAPlaceWhenEmpty() {
        #expect(WorldClock.results(for: " ", now: noonUTC, local: copenhagen, locale: english) == [.hint("Type a city or time zone")])
    }

    @Test func showsTimeInSearch() {
        let results = SearchResults(links: [], apps: [], usage: [:], timeZone: copenhagen, now: noonUTC).results(for: "time in tokyo")
        #expect(results.first?.id == "time:Tokyo")
    }
}
