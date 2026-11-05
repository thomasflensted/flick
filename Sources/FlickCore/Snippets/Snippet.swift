import Foundation

public struct Snippet: Codable, Identifiable, Hashable, Listable {
    public var id: UUID
    public var name: String
    public var text: String
    public var keyword: String?

    public init(id: UUID = UUID(), name: String, text: String, keyword: String? = nil) {
        self.id = id
        self.name = name
        self.text = text
        self.keyword = keyword
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        text = try c.decode(String.self, forKey: .text)
        keyword = try c.decodeIfPresent(String.self, forKey: .keyword).nilIfEmpty
    }

    public func isDuplicate(of other: Snippet) -> Bool {
        id == other.id || (name == other.name && text == other.text)
    }

    public func expanded(id: () -> String = NanoID.make) -> String {
        SnippetTemplate.expand(text, id: id)
    }
}
