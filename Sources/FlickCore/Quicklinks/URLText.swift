import Foundation

public enum URLText {
    public static func hasScheme(_ text: String) -> Bool {
        text.range(of: #"^[a-zA-Z][a-zA-Z0-9+.-]*:"#, options: .regularExpression) != nil
    }

    public static func encodedForQuery(_ text: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=?#")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
    }

    public static func isPath(_ text: String) -> Bool {
        text.hasPrefix("/") || text.hasPrefix("~")
    }

    public static func expandingTilde(_ path: String) -> String {
        path.hasPrefix("~") ? NSHomeDirectory() + path.dropFirst() : path
    }

    public static func url(from text: String) -> URL? {
        let text = text.trimmingCharacters(in: .whitespaces)
        if isPath(text) { return URL(fileURLWithPath: expandingTilde(text)) }
        if hasScheme(text) { return URL(string: text) }
        return URL(string: "https://" + text)
    }

    public static func looksLikeWebAddress(_ text: String) -> Bool {
        guard !text.contains(" "), text.contains(".") else { return false }
        return hasScheme(text) || url(from: text)?.host?.contains(".") == true
    }

    public static func googleSearch(_ query: String) -> URL {
        URL(string: "https://www.google.com/search?q=" + encodedForQuery(query))!
    }
}
