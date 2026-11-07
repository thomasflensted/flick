import FlickCore
import Foundation
import MapKit

final class WeatherSearch: NSObject, MKLocalSearchCompleterDelegate {
    var onUpdate: () -> Void = {}
    private(set) var reports: [WeatherReport] = []
    private let completer = MKLocalSearchCompleter()
    private var task: Task<Void, Never>?
    private var cache: [URL: (weather: Weather, fetched: Date)] = [:]

    private static let limit = 5
    private static let maxAge: TimeInterval = 10 * 60

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func search(_ query: String) {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { clear(); return }
        completer.queryFragment = text
    }

    func clear() {
        task?.cancel()
        completer.cancel()
        reports = []
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let completions = Array(completer.results.prefix(Self.limit))
        task?.cancel()
        task = Task { @MainActor in
            let found = await reports(for: completions)
            guard !Task.isCancelled else { return }
            reports = found
            onUpdate()
        }
    }

    @MainActor private func reports(for completions: [MKLocalSearchCompletion]) async -> [WeatherReport] {
        await withTaskGroup(of: (Int, WeatherReport?).self) { group in
            for (index, completion) in completions.enumerated() {
                group.addTask { @MainActor in (index, await self.report(for: completion)) }
            }
            var found: [(index: Int, report: WeatherReport)] = []
            for await (index, report) in group {
                if let report { found.append((index, report)) }
            }
            return found.sorted { $0.index < $1.index }.map(\.report)
        }
    }

    @MainActor private func report(for completion: MKLocalSearchCompletion) async -> WeatherReport? {
        guard let place = await place(for: completion) else { return nil }
        return WeatherReport(place: place, weather: await weather(at: place))
    }

    @MainActor private func place(for completion: MKLocalSearchCompletion) async -> WeatherPlace? {
        guard let item = try? await MKLocalSearch(request: MKLocalSearch.Request(completion: completion)).start().mapItems.first else { return nil }
        let coordinate = item.placemark.coordinate
        return WeatherPlace(name: completion.title, region: completion.subtitle,
                            latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    @MainActor private func weather(at place: WeatherPlace) async -> Weather? {
        let url = YrAPI.forecastURL(place)
        if let cached = cache[url], Date().timeIntervalSince(cached.fetched) < Self.maxAge { return cached.weather }
        var request = URLRequest(url: url)
        request.setValue(YrAPI.userAgent, forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request), let weather = try? YrAPI.parse(data) else { return nil }
        cache[url] = (weather, Date())
        return weather
    }
}
