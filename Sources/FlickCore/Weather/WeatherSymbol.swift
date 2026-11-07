public enum WeatherSymbol {
    static let descriptions = [
        "clearsky": "Clear sky", "fair": "Fair", "partlycloudy": "Partly cloudy", "cloudy": "Cloudy", "fog": "Fog",
        "rain": "Rain", "sleet": "Sleet", "snow": "Snow",
        "rainshowers": "Rain showers", "sleetshowers": "Sleet showers", "snowshowers": "Snow showers",
    ]

    public static func description(_ code: String) -> String {
        let condition = Condition(code)
        let base = descriptions[condition.kind] ?? condition.kind.capitalized
        let intensity = condition.intensity.map { "\($0.capitalized) \(base.lowercased())" } ?? base
        return condition.thunder ? "\(intensity) and thunder" : intensity
    }

    public static func sfSymbol(_ code: String) -> String {
        let condition = Condition(code)
        let night = code.hasSuffix("_night")
        if condition.thunder { return "cloud.bolt.rain.fill" }
        switch condition.kind {
        case "clearsky": return night ? "moon.stars.fill" : "sun.max.fill"
        case "fair", "partlycloudy": return night ? "cloud.moon.fill" : "cloud.sun.fill"
        case "cloudy": return "cloud.fill"
        case "fog": return "cloud.fog.fill"
        case "rainshowers": return night ? "cloud.moon.rain.fill" : "cloud.sun.rain.fill"
        case "rain": return condition.intensity == "heavy" ? "cloud.heavyrain.fill" : "cloud.rain.fill"
        case "sleet", "sleetshowers": return "cloud.sleet.fill"
        case "snow", "snowshowers": return "cloud.snow.fill"
        default: return "cloud.fill"
        }
    }

    struct Condition {
        let kind: String
        let intensity: String?
        let thunder: Bool

        init(_ code: String) {
            var kind = String(code.split(separator: "_").first ?? "")
            thunder = kind.hasSuffix("andthunder")
            if thunder { kind.removeLast("andthunder".count) }
            intensity = ["light", "heavy"].first { kind.hasPrefix($0) }
            if let intensity { kind.removeFirst(intensity.count) }
            self.kind = kind
        }
    }
}
