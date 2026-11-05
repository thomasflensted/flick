import Foundation

public enum RaycastExport {
    private struct Root: Decodable {
        let builtin_package_quicklinks: Package
    }

    private struct Package: Decodable {
        let quicklinks: [Link]
    }

    private struct Link: Decodable {
        let uuid: UUID
        let name: String
        let url: String
    }

    public static func quicklinks(fromJSON data: Data) throws -> [Quicklink] {
        try JSONDecoder().decode(Root.self, from: data).builtin_package_quicklinks.quicklinks.map {
            Quicklink(id: $0.uuid, name: $0.name, link: $0.url)
        }
    }
}
