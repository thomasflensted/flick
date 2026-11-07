import Foundation

public struct ClockTime: Equatable {
    public let hour: Int
    public let minute: Int
}

public struct TimeQuery: Equatable {
    public let time: ClockTime?
    public let from: Place?
    public let to: Place?

    private static let nowPattern = try! Regex(#"^(?:time\s+(?:in\s+)?(?<prefixed>.+)|(?<suffixed>.+?)\s+time)$"#)
    private static let clockPattern = try! Regex(
        #"^(?<hour>\d{1,2})(?::(?<minute>\d{2}))?\s*(?<meridiem>am|pm)?(?:\s*(?<from>.+?))??(?:\s+(?:to|in)\s+(?<to>.+))?$"#)

    public static func parse(_ query: String) -> TimeQuery? {
        let text = query.trimmingCharacters(in: .whitespaces).lowercased()
        return parseNow(text) ?? parseClock(text)
    }

    static func parseNow(_ text: String) -> TimeQuery? {
        guard let match = try? nowPattern.wholeMatch(in: text),
              let name = match["prefixed"]?.substring ?? match["suffixed"]?.substring,
              let place = Place.find(String(name)) else { return nil }
        return TimeQuery(time: nil, from: nil, to: place)
    }

    static func parseClock(_ text: String) -> TimeQuery? {
        guard let match = try? clockPattern.wholeMatch(in: text),
              let hourText = match["hour"]?.substring, let hour = Int(hourText) else { return nil }
        let minuteText = match["minute"]?.substring
        let meridiem = match["meridiem"]?.substring.map(String.init)
        guard minuteText != nil || meridiem != nil,
              let time = clockTime(hour: hour, minute: minuteText.flatMap { Int($0) } ?? 0, meridiem: meridiem) else { return nil }
        let names = ["from", "to"].map { match[$0]?.substring.map(String.init) }
        let places = names.map { $0.flatMap(Place.find) }
        guard names.contains(where: { $0 != nil }), zip(names, places).allSatisfy({ ($0 == nil) == ($1 == nil) }) else { return nil }
        return TimeQuery(time: time, from: places[0], to: places[1])
    }

    static func clockTime(hour: Int, minute: Int, meridiem: String?) -> ClockTime? {
        guard (0...59).contains(minute) else { return nil }
        guard let meridiem else { return (0...23).contains(hour) ? ClockTime(hour: hour, minute: minute) : nil }
        guard (1...12).contains(hour) else { return nil }
        let base = hour % 12
        return ClockTime(hour: meridiem == "pm" ? base + 12 : base, minute: minute)
    }
}
