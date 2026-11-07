import Foundation

public struct Place: Equatable {
    public let name: String
    public let timeZone: TimeZone

    public static func local(_ timeZone: TimeZone) -> Place {
        Place(name: cityName(timeZone.identifier), timeZone: timeZone)
    }

    public static func find(_ text: String) -> Place? {
        let key = text.trimmingCharacters(in: .whitespaces).lowercased()
        return all.first { $0.name.lowercased() == key }
    }

    public static let all: [Place] = cities + abbreviations

    static let cities: [Place] = TimeZone.knownTimeZoneIdentifiers.compactMap { identifier in
        TimeZone(identifier: identifier).map { Place(name: cityName(identifier), timeZone: $0) }
    }

    static let abbreviations: [Place] = TimeZone.abbreviationDictionary.sorted { $0.key < $1.key }.compactMap { abbreviation, identifier in
        TimeZone(identifier: identifier).map { Place(name: abbreviation, timeZone: $0) }
    }

    static func cityName(_ identifier: String) -> String {
        String(identifier.split(separator: "/").last ?? Substring(identifier)).replacingOccurrences(of: "_", with: " ")
    }
}
