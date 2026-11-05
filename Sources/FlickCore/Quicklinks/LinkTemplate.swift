import Foundation

public enum LinkTemplate {
    private static let argumentPattern = try! NSRegularExpression(pattern: #"\{argument((?:\s+[a-z]+="[^"]*")*)\s*\}"#)
    private static let attributePattern = try! NSRegularExpression(pattern: #"([a-z]+)="([^"]*)""#)

    public static func takesArgument(_ link: String) -> Bool {
        !matches(in: link).isEmpty
    }

    public static func argumentLabel(_ link: String) -> String {
        matches(in: link).lazy.compactMap { attributes(of: $0, in: link)["name"] }.first ?? "Query"
    }

    public static func resolve(_ link: String, argument: String) -> String {
        let encode = URLText.hasScheme(link)
        var out = ""
        var cursor = link.startIndex
        for match in matches(in: link) {
            guard let range = Range(match.range, in: link) else { continue }
            out += link[cursor..<range.lowerBound]
            let value = argument.isEmpty ? attributes(of: match, in: link)["default"] ?? "" : argument
            out += encode ? URLText.encodedForQuery(value) : value
            cursor = range.upperBound
        }
        return out + link[cursor...]
    }

    private static func matches(in link: String) -> [NSTextCheckingResult] {
        argumentPattern.matches(in: link, range: NSRange(link.startIndex..., in: link))
    }

    private static func attributes(of match: NSTextCheckingResult, in link: String) -> [String: String] {
        guard let range = Range(match.range(at: 1), in: link) else { return [:] }
        let text = String(link[range])
        var result: [String: String] = [:]
        for m in attributePattern.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let key = Range(m.range(at: 1), in: text), let value = Range(m.range(at: 2), in: text) {
                result[String(text[key])] = String(text[value])
            }
        }
        return result
    }
}
