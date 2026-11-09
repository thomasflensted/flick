import FlickCore

final class WeatherSource: ModeSource {
    var onUpdate: () -> Void {
        get { weather.onUpdate }
        set { weather.onUpdate = newValue }
    }
    private let weather = WeatherSearch()

    func enter() {
        weather.clear()
    }

    func queryChanged(_ query: String) {
        weather.search(query)
    }

    func results(for query: String) -> [ResultItem] {
        WeatherResults.results(for: query, reports: weather.reports)
    }
}
