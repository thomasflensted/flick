import Foundation

public enum WorldClock {
    static let limit = 20

    public static func results(for query: String, now: Date, local: TimeZone, locale: Locale) -> [ResultItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [.hint("Type a city or time zone")] }
        let reference = Place.local(local)
        return Ranker(usage: [:]).rank(Place.all, query: query, texts: { [$0.name] }, key: \.name)
            .prefix(limit)
            .map { .time(ZoneTime(date: now, place: $0, reference: reference), locale: locale) }
    }
}
