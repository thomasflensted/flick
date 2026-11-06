import Foundation

public struct Conversion: Equatable {
    public let amount: Double
    public let from: String
    public let value: Double
    public let to: String
    public let rate: Double

    public func formattedValue(_ locale: Locale) -> String {
        "\(Self.format(value, locale: locale)) \(to)"
    }

    public func plainValue(_ locale: Locale) -> String {
        value.formatted(.number.precision(.fractionLength(2)).grouping(.never).locale(locale))
    }

    public func summary(_ locale: Locale) -> String {
        let rateText = rate.formatted(.number.precision(.significantDigits(1...5)).locale(locale))
        return "\(Self.format(amount, locale: locale)) \(from) · 1 \(from) = \(rateText) \(to)"
    }

    static func format(_ value: Double, locale: Locale) -> String {
        value.formatted(.number.precision(.fractionLength(2)).locale(locale))
    }
}

public enum CurrencyConverter {
    static let fallbackTargets = ["EUR", "USD"]
    static let defaultTargetCount = 2

    public static func conversions(for query: String, rates: CurrencyRates, local: String) -> [Conversion] {
        guard let money = MoneyQuery.parse(query, known: rates.codes, local: local) else { return [] }
        return targets(for: money, local: local).compactMap { to in
            rates.rate(from: money.from, to: to).map {
                Conversion(amount: money.amount, from: money.from, value: money.amount * $0, to: to, rate: $0)
            }
        }
    }

    static func targets(for money: MoneyQuery, local: String) -> [String] {
        if let to = money.to { return [to] }
        var seen = Set<String>()
        let candidates = ([local] + fallbackTargets).filter { $0 != money.from && seen.insert($0).inserted }
        return Array(candidates.prefix(defaultTargetCount))
    }
}
