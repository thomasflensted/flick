import Foundation

public enum RaycastExport {
    private struct Root: Decodable {
        let builtin_package_quicklinks: QuicklinkPackage?
        let builtin_package_snippets: SnippetPackage?
    }

    private struct QuicklinkPackage: Decodable {
        let quicklinks: [RaycastQuicklink]
    }

    private struct RaycastQuicklink: Decodable {
        let uuid: UUID
        let name: String
        let url: String
    }

    private struct SnippetPackage: Decodable {
        let snippets: [RaycastSnippet]
    }

    private struct RaycastSnippet: Decodable {
        let name: String
        let text: String
        let alias: String?
    }

    public struct Contents: Equatable {
        public let quicklinks: [Quicklink]
        public let snippets: [Snippet]
    }

    public struct NothingToImport: LocalizedError {
        public var errorDescription: String? { "The file contains no quicklinks or snippets." }
    }

    public static func contents(fromJSON data: Data) throws -> Contents {
        let root = try JSONDecoder().decode(Root.self, from: data)
        let quicklinks = root.builtin_package_quicklinks?.quicklinks.map {
            Quicklink(id: $0.uuid, name: $0.name, link: $0.url)
        } ?? []
        let snippets = root.builtin_package_snippets?.snippets.map {
            Snippet(name: $0.name, text: SnippetTemplate.fromRaycast($0.text), keyword: $0.alias)
        } ?? []
        guard !quicklinks.isEmpty || !snippets.isEmpty else { throw NothingToImport() }
        return Contents(quicklinks: quicklinks, snippets: snippets)
    }
}
