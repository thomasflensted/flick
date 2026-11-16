import Foundation

public struct Calculation: Equatable {
    public let expression: String
    public let value: Double

    static let maximumDecimals = 10

    public static func evaluate(_ text: String) -> Calculation? {
        var parser = ArithmeticParser(text)
        guard let value = parser.parse(), parser.hasOperation, value.isFinite else { return nil }
        return Calculation(expression: text, value: value)
    }

    public func formattedValue(_ locale: Locale) -> String {
        value.formatted(Self.style.locale(locale))
    }

    public func plainValue(_ locale: Locale) -> String {
        value.formatted(Self.style.grouping(.never).locale(locale))
    }

    private static var style: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(0...maximumDecimals))
    }
}
