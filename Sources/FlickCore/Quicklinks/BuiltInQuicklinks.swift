import Foundation

extension Quicklink {
    public static let googleSearch = Quicklink(
        id: UUID(uuidString: "8AED846F-F8C3-45F9-B5B5-290F00177849")!,
        name: "Search Google",
        link: "https://www.google.com/search?q={argument}",
        keyword: "g"
    )

    public static let googleMaps = Quicklink(
        id: UUID(uuidString: "5C0B5F0E-6D1A-4E7B-9C2F-3A8D41E7B6C9")!,
        name: "Search Google Maps",
        link: "https://www.google.com/maps/search/?api=1&query={argument}",
        keyword: "gm"
    )

    public static let builtIns: [Quicklink] = [.googleSearch, .googleMaps]
}
