import Foundation

public struct CurrencyRates: Codable, Equatable {
    public let base: String
    public let updated: Date
    public let rates: [String: Double]

    static let maxAge: TimeInterval = 12 * 60 * 60

    public init(base: String, updated: Date, rates: [String: Double]) {
        self.base = base
        self.updated = updated
        self.rates = rates
    }

    public var codes: Set<String> { Set(rates.keys) }

    public func rate(from: String, to: String) -> Double? {
        guard let fromRate = rates[from], let toRate = rates[to], fromRate > 0 else { return nil }
        return toRate / fromRate
    }

    public func isStale(now: Date) -> Bool {
        now.timeIntervalSince(updated) > Self.maxAge
    }
}

public enum ExchangeRateAPI {
    public static let url = URL(string: "https://open.er-api.com/v6/latest/USD")!

    private struct Response: Decodable {
        let base_code: String
        let time_last_update_unix: TimeInterval
        let rates: [String: Double]
    }

    public static func parse(_ data: Data) throws -> CurrencyRates {
        let response = try JSONDecoder().decode(Response.self, from: data)
        return CurrencyRates(base: response.base_code, updated: Date(timeIntervalSince1970: response.time_last_update_unix),
                             rates: response.rates)
    }
}
