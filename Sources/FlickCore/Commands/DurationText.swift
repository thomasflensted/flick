import Foundation

public enum DurationText {
    private static let pattern = try! NSRegularExpression(pattern: #"^(?:(\d+)\s*h)?\s*(?:(\d+)\s*m?)?$"#)

    public static func minutes(from text: String) -> Int? {
        let text = text.trimmingCharacters(in: .whitespaces).lowercased()
        guard !text.isEmpty,
              let match = pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        let hours = number(at: 1, in: match, of: text)
        let minutes = number(at: 2, in: match, of: text)
        let total = hours * 60 + minutes
        return total > 0 ? total : nil
    }

    public static func format(minutes: Int) -> String {
        let hours = minutes / 60, rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest) min"
        case (_, 0): return "\(hours) h"
        default: return "\(hours) h \(rest) min"
        }
    }

    private static func number(at group: Int, in match: NSTextCheckingResult, of text: String) -> Int {
        Range(match.range(at: group), in: text).flatMap { Int(text[$0]) } ?? 0
    }
}
