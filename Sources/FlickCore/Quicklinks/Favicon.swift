import Foundation

public enum Favicon {
    static let minimumSharpWidth = 24

    public static func isSharp(pixelWidth: Int) -> Bool {
        pixelWidth >= minimumSharpWidth
    }

    public static func hosts(for host: String) -> [String] {
        let labels = host.split(separator: ".")
        guard labels.count > 2 else { return [host] }
        return (0...(labels.count - 2)).map { labels[$0...].joined(separator: ".") }
    }

    public static func url(for host: String) -> URL {
        var components = URLComponents(string: "https://www.google.com/s2/favicons")!
        components.queryItems = [.init(name: "domain", value: host), .init(name: "sz", value: "64")]
        return components.url!
    }
}
