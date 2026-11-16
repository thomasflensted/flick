struct ArithmeticParser {
    private var remaining: Substring
    private(set) var hasOperation = false

    init(_ text: String) {
        remaining = Substring(text.filter { !$0.isWhitespace })
    }

    mutating func parse() -> Double? {
        guard let value = sum(), remaining.isEmpty else { return nil }
        return value
    }

    private mutating func sum() -> Double? {
        guard var value = product() else { return nil }
        while let sign = take("+", "-") {
            guard let next = product() else { return nil }
            value = sign == "+" ? value + next : value - next
        }
        return value
    }

    private mutating func product() -> Double? {
        guard var value = factor() else { return nil }
        while let sign = take("*", "/") {
            guard let next = factor() else { return nil }
            value = sign == "*" ? value * next : value / next
        }
        return value
    }

    private mutating func factor() -> Double? {
        if take("-") != nil { return factor().map { -$0 } }
        guard take("(") != nil else { return number() }
        guard let value = sum(), take(")") != nil else { return nil }
        return value
    }

    private mutating func number() -> Double? {
        let digits = remaining.prefix { $0.isNumber || $0 == "." || $0 == "," }
        remaining = remaining.dropFirst(digits.count)
        return MoneyQuery.amount(from: String(digits))
    }

    private mutating func take(_ signs: Character...) -> Character? {
        guard let first = remaining.first, signs.contains(first) else { return nil }
        remaining.removeFirst()
        if signs.count > 1 { hasOperation = true }
        return first
    }
}
