import Foundation

public struct AIModel: Decodable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let created: Int

    public init(id: String, name: String, created: Int) {
        self.id = id
        self.name = name
        self.created = created
    }
}

public enum ModelCatalog {
    private struct Response: Decodable {
        let data: [AIModel]
    }

    static let preferredFamily = "anthropic/claude-sonnet"

    public static func models(fromJSON data: Data) throws -> [AIModel] {
        try JSONDecoder().decode(Response.self, from: data).data
    }

    public static func preferredDefault(in models: [AIModel]) -> AIModel? {
        models.filter { $0.id.hasPrefix(preferredFamily) }.max { $0.created < $1.created } ?? models.first
    }

    public static func search(_ query: String, in models: [AIModel]) -> [AIModel] {
        Ranker(usage: [:]).rank(models, query: query, texts: { [$0.name, $0.id] }, key: \.id)
    }
}
