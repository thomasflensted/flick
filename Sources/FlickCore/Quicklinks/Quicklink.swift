import Foundation

public struct Quicklink: Codable, Identifiable, Hashable, Listable {
    public var id: UUID
    public var name: String
    public var link: String
    public var openWith: String?
    public var keyword: String?

    public init(id: UUID = UUID(), name: String, link: String, openWith: String? = nil, keyword: String? = nil) {
        self.id = id
        self.name = name
        self.link = link
        self.openWith = openWith
        self.keyword = keyword
    }

    // `id` is optional in the JSON so the file can be written by hand or by an agent.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        link = try c.decode(String.self, forKey: .link)
        openWith = try c.decodeIfPresent(String.self, forKey: .openWith).nilIfEmpty
        keyword = try c.decodeIfPresent(String.self, forKey: .keyword).nilIfEmpty
    }

    public var takesArgument: Bool { LinkTemplate.takesArgument(link) }
    public var argumentLabel: String { LinkTemplate.argumentLabel(link) }
    public var trigger: String { keyword ?? name }

    public var webHost: String? {
        guard let url = URLText.url(from: resolved(argument: "x")), ["http", "https"].contains(url.scheme) else { return nil }
        return url.host
    }

    public func resolved(argument: String) -> String {
        LinkTemplate.resolve(link, argument: argument)
    }

    public func isDuplicate(of other: Quicklink) -> Bool {
        id == other.id || (name == other.name && link == other.link)
    }

    public func isTriggered(by text: String) -> Bool {
        let text = text.lowercased()
        return [keyword, name].compactMap { $0?.lowercased() }.contains(text)
    }
}

extension Optional where Wrapped == String {
    var nilIfEmpty: String? { self?.isEmpty == false ? self : nil }
}
