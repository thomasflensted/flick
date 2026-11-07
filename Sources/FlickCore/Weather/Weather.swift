import Foundation

public struct Weather: Equatable {
    public let temperature: Double
    public let windSpeed: Double
    public let symbolCode: String

    public init(temperature: Double, windSpeed: Double, symbolCode: String) {
        self.temperature = temperature
        self.windSpeed = windSpeed
        self.symbolCode = symbolCode
    }

    public var temperatureText: String { "\(Int(temperature.rounded()))°" }

    public var details: String {
        "\(WeatherSymbol.description(symbolCode)) · \(Int(windSpeed.rounded())) m/s wind"
    }
}

public struct WeatherPlace: Hashable {
    public let name: String
    public let region: String
    public let latitude: Double
    public let longitude: Double

    public init(name: String, region: String, latitude: Double, longitude: Double) {
        self.name = name
        self.region = region
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct WeatherReport: Equatable {
    public let place: WeatherPlace
    public let weather: Weather?

    public init(place: WeatherPlace, weather: Weather?) {
        self.place = place
        self.weather = weather
    }

    public var title: String {
        weather.map { "\(place.name) · \($0.temperatureText)" } ?? place.name
    }

    public var subtitle: String {
        [weather?.details ?? "No weather data", place.region].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

public enum WeatherResults {
    public static func results(for query: String, reports: [WeatherReport]) -> [ResultItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [.hint("Type a place to see its weather")] }
        return reports.map(ResultItem.weather)
    }
}
