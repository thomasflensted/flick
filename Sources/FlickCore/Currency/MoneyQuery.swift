import Foundation

public struct MoneyQuery: Equatable {
    public let amount: Double
    public let from: String
    public let to: String?

    private static let pattern = try! Regex(
        #"^(?<prefix>[$€£¥])?\s*(?<amount>\d[\d.,]*)(?<thousands>k)?\s*(?<from>[a-z$€£¥]+)?(?:(?:\s*(?:to|in|=|>|->|→)\s*|\s+)(?<to>[a-z$€£¥]+))?$"#)

    public static func parse(_ query: String, known codes: Set<String>, local: String) -> MoneyQuery? {
        let text = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard let match = try? pattern.wholeMatch(in: text),
              let amountText = match["amount"]?.substring, let amount = amount(from: String(amountText)) else { return nil }
        let tokens = ["prefix", "from", "to"].compactMap { match[$0]?.substring }
        let currencies = tokens.compactMap { code(for: String($0), known: codes, local: local) }
        guard currencies.count == tokens.count, (1...2).contains(currencies.count) else { return nil }
        let multiplier: Double = match["thousands"]?.substring == nil ? 1 : 1000
        return MoneyQuery(amount: amount * multiplier, from: currencies[0], to: currencies.dropFirst().first)
    }

    static func code(for token: String, known codes: Set<String>, local: String) -> String? {
        let upper = token.uppercased()
        if codes.contains(upper) { return upper }
        switch token {
        case "$", "dollar", "dollars": return "USD"
        case "€", "euro", "euros": return "EUR"
        case "£", "pound", "pounds": return "GBP"
        case "¥", "yen": return "JPY"
        case "kr", "krone", "kroner", "kronor": return ["DKK", "SEK", "NOK"].contains(local) ? local : "DKK"
        default: return nil
        }
    }

    static func amount(from text: String) -> Double? {
        let separators = text.filter { $0 == "." || $0 == "," }
        guard let last = separators.last else { return Double(text) }
        let decimal: Character?
        if Set(separators).count > 1 {
            decimal = last
        } else if separators.count > 1 {
            decimal = nil
        } else {
            let digitsAfter = text.split(separator: last, omittingEmptySubsequences: false).last?.count ?? 0
            decimal = digitsAfter == 3 ? nil : last
        }
        let normalized = text.compactMap { char -> Character? in
            if char == decimal { return "." }
            return char.isNumber ? char : nil
        }
        return Double(String(normalized))
    }
}
