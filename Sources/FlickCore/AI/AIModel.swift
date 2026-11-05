import Foundation

public struct AIModel: Decodable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let created: Int
    public let outputPricePerMillion: Double?

    public init(id: String, name: String, created: Int, outputPricePerMillion: Double? = nil) {
        self.id = id
        self.name = name
        self.created = created
        self.outputPricePerMillion = outputPricePerMillion
    }

    private struct Pricing: Decodable {
        let completion: String
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, created, pricing
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        created = try c.decode(Int.self, forKey: .created)
        let perToken = try c.decodeIfPresent(Pricing.self, forKey: .pricing).flatMap { Double($0.completion) }
        outputPricePerMillion = perToken.map { $0 * 1_000_000 }
    }

    public var isVariant: Bool { id.contains(":") }

    public var priceText: String? {
        outputPricePerMillion.map { $0 == 0 ? "Free" : String(format: "$%.2f / 1M", $0) }
    }
}

public enum ModelCatalog {
    private struct Response: Decodable {
        let data: [AIModel]
    }

    static let preferredFamily = "anthropic/claude-sonnet"
    public static let popularCategories = ["programming", "technology", "trivia"]

    public static func models(fromJSON data: Data) throws -> [AIModel] {
        try JSONDecoder().decode(Response.self, from: data).data
    }

    public static func categoryURL(_ category: String) -> URL {
        URL(string: "\(OpenRouter.modelsURL.absoluteString)?category=\(category)")!
    }

    public static func preferredDefault(in models: [AIModel]) -> AIModel? {
        models.filter { $0.id.hasPrefix(preferredFamily) && !$0.isVariant }.max { $0.created < $1.created } ?? models.first
    }

    public static func merged(_ lists: [[AIModel]]) -> [AIModel] {
        var seen = Set<String>()
        return lists.joined().filter { seen.insert($0.id).inserted }.sorted { $0.name < $1.name }
    }

    public static func visible(query: String, popular: [AIModel], all: [AIModel], selectedID: String?) -> [AIModel] {
        let all = all.filter { !$0.isVariant }
        if !query.trimmingCharacters(in: .whitespaces).isEmpty { return search(query, in: all) }
        let selected = all.filter { $0.id == selectedID && !popular.contains($0) }
        return selected + popular
    }

    public static func search(_ query: String, in models: [AIModel]) -> [AIModel] {
        Ranker(usage: [:]).rank(models, query: query, texts: { [$0.name, $0.id] }, key: \.id)
    }
}
