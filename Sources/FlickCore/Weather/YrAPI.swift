import Foundation

public enum YrAPI {
    public static let userAgent = "Flick github.com/thomasflensted/flick"
    static let cacheLifetime: TimeInterval = 10 * 60

    struct Malformed: Error {}

    private struct Response: Decodable {
        let properties: Properties
        struct Properties: Decodable { let timeseries: [Entry] }
        struct Entry: Decodable { let data: EntryData }
        struct EntryData: Decodable {
            let instant: Instant
            let next_1_hours: Period?
            let next_6_hours: Period?
        }
        struct Instant: Decodable { let details: Details }
        struct Details: Decodable {
            let air_temperature: Double
            let wind_speed: Double
        }
        struct Period: Decodable { let summary: Summary }
        struct Summary: Decodable { let symbol_code: String }
    }

    public static func forecastURL(_ place: WeatherPlace) -> URL {
        var components = URLComponents(string: "https://api.met.no/weatherapi/locationforecast/2.0/compact")!
        components.queryItems = [.init(name: "lat", value: coordinate(place.latitude)), .init(name: "lon", value: coordinate(place.longitude))]
        return components.url!
    }

    public static func pageURL(_ place: WeatherPlace) -> URL {
        URL(string: "https://www.yr.no/en/forecast/daily-table/\(coordinate(place.latitude)),\(coordinate(place.longitude))")!
    }

    public static func parse(_ data: Data) throws -> Weather {
        let response = try JSONDecoder().decode(Response.self, from: data)
        guard let now = response.properties.timeseries.first?.data,
              let symbol = (now.next_1_hours ?? now.next_6_hours)?.summary.symbol_code else { throw Malformed() }
        return Weather(temperature: now.instant.details.air_temperature, windSpeed: now.instant.details.wind_speed, symbolCode: symbol)
    }

    public static func isFresh(fetchedAt: Date, now: Date) -> Bool {
        now.timeIntervalSince(fetchedAt) < cacheLifetime
    }

    static func coordinate(_ value: Double) -> String {
        String(format: "%.4f", value)
    }
}
