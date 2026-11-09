import FlickCore
import Foundation

final class TimeZonesSource: ModeSource {
    var onUpdate: () -> Void = {}

    func results(for query: String) -> [ResultItem] {
        WorldClock.results(for: query, now: Date(), local: .current, locale: .current)
    }
}
