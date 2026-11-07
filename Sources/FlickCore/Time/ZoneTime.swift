import Foundation

public struct ZoneTime: Equatable {
    public let date: Date
    public let place: Place
    public let reference: Place

    public static func answer(for query: String, now: Date, local: TimeZone) -> ZoneTime? {
        guard let parsed = TimeQuery.parse(query) else { return nil }
        let localPlace = Place.local(local)
        let from = parsed.from ?? localPlace
        let to = parsed.to ?? localPlace
        guard let date = parsed.time.map({ date(of: $0, in: from.timeZone, on: now) }) ?? now else { return nil }
        return ZoneTime(date: date, place: to, reference: from)
    }

    static func date(of time: ClockTime, in zone: TimeZone, on day: Date) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        var parts = calendar.dateComponents([.year, .month, .day], from: day)
        parts.hour = time.hour
        parts.minute = time.minute
        return calendar.date(from: parts)
    }

    public func time(_ locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = place.timeZone
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public func title(_ locale: Locale) -> String {
        "\(time(locale)) in \(place.name)"
    }

    public func summary(_ locale: Locale) -> String {
        let day = date.formatted(Date.FormatStyle(locale: locale, timeZone: place.timeZone).weekday(.abbreviated).day().month(.abbreviated))
        return "\(day) · \(offsetText)"
    }

    var offsetMinutes: Int {
        (place.timeZone.secondsFromGMT(for: date) - reference.timeZone.secondsFromGMT(for: date)) / 60
    }

    var offsetText: String {
        let minutes = offsetMinutes
        if minutes == 0 { return "Same time as \(reference.name)" }
        let direction = minutes > 0 ? "ahead of" : "behind"
        return "\(DurationText.format(minutes: abs(minutes))) \(direction) \(reference.name)"
    }
}
