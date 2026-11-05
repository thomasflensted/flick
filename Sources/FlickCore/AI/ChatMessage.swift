public struct ChatMessage: Codable, Equatable, Identifiable {
    public enum Role: String, Codable {
        case user, assistant
    }

    public let id: Int
    public let role: Role
    public var content: String

    public init(id: Int, role: Role, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }

    private enum CodingKeys: String, CodingKey {
        case role, content
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = 0
        role = try c.decode(Role.self, forKey: .role)
        content = try c.decode(String.self, forKey: .content)
    }
}
