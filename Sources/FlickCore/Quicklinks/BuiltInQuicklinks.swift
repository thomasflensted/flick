import Foundation

extension Quicklink {
    public static let googleSearch = Quicklink(
        id: UUID(uuidString: "8AED846F-F8C3-45F9-B5B5-290F00177849")!,
        name: "Search Google",
        link: "https://www.google.com/search?q={argument}",
        keyword: "g"
    )
}
