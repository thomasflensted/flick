import Foundation

public struct Place: Equatable {
    public let name: String
    public let timeZone: TimeZone

    public static func local(_ timeZone: TimeZone) -> Place {
        Place(name: cityName(timeZone.identifier), timeZone: timeZone)
    }

    public static func find(_ text: String) -> Place? {
        let key = text.trimmingCharacters(in: .whitespaces).lowercased()
        if let identifier = cities[key], let zone = TimeZone(identifier: identifier) {
            return Place(name: cityName(identifier), timeZone: zone)
        }
        let abbreviation = key.uppercased()
        guard let identifier = TimeZone.abbreviationDictionary[abbreviation], let zone = TimeZone(identifier: identifier) else { return nil }
        return Place(name: abbreviation, timeZone: zone)
    }

    static let cities: [String: String] = Dictionary(
        TimeZone.knownTimeZoneIdentifiers.map { (cityName($0).lowercased(), $0) }, uniquingKeysWith: { first, _ in first })

    static func cityName(_ identifier: String) -> String {
        String(identifier.split(separator: "/").last ?? Substring(identifier)).replacingOccurrences(of: "_", with: " ")
    }
}
