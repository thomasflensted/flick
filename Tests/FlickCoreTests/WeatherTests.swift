import Foundation
import Testing
@testable import FlickCore

struct WeatherTests {
    let copenhagen = WeatherPlace(name: "Copenhagen", region: "Denmark", latitude: 55.676098, longitude: 12.568337)

    @Test func describesSymbolCodes() {
        #expect(WeatherSymbol.description("partlycloudy_day") == "Partly cloudy")
        #expect(WeatherSymbol.description("lightrainshowers_night") == "Light rain showers")
        #expect(WeatherSymbol.description("heavysnowandthunder") == "Heavy snow and thunder")
        #expect(WeatherSymbol.description("cloudy") == "Cloudy")
    }

    @Test func picksSymbolsForDayAndNight() {
        #expect(WeatherSymbol.sfSymbol("clearsky_day") == "sun.max.fill")
        #expect(WeatherSymbol.sfSymbol("clearsky_night") == "moon.stars.fill")
        #expect(WeatherSymbol.sfSymbol("rainandthunder") == "cloud.bolt.rain.fill")
    }

    @Test func parsesTheCurrentHourFromYr() throws {
        let json = #"{"properties":{"timeseries":[{"time":"2026-11-07T19:00:00Z","data":{"instant":{"details":{"air_temperature":7.9,"wind_speed":3.5}},"next_1_hours":{"summary":{"symbol_code":"cloudy"},"details":{}}}}]}}"#
        #expect(try YrAPI.parse(Data(json.utf8)) == Weather(temperature: 7.9, windSpeed: 3.5, symbolCode: "cloudy"))
    }

    @Test func roundsCoordinatesToFourDecimals() {
        #expect(YrAPI.forecastURL(copenhagen).query == "lat=55.6761&lon=12.5683")
        #expect(YrAPI.pageURL(copenhagen).absoluteString == "https://www.yr.no/en/forecast/daily-table/55.6761,12.5683")
    }

    @Test func showsTemperatureInTitleAndConditionsInSubtitle() {
        let report = WeatherReport(place: copenhagen, weather: Weather(temperature: 7.6, windSpeed: 3.5, symbolCode: "cloudy"))
        #expect(report.title == "Copenhagen · 8°")
        #expect(report.subtitle == "Cloudy · 4 m/s wind · Denmark")
    }

    @Test func saysSoWhenWeatherIsMissing() {
        #expect(WeatherReport(place: copenhagen, weather: nil).subtitle == "No weather data · Denmark")
    }

    @Test func asksForAPlaceWhenEmpty() {
        #expect(WeatherResults.results(for: "", reports: []) == [.hint("Type a place to see its weather")])
    }
}
