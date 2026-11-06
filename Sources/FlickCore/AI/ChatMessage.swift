import Foundation

public struct ChatMessage: Codable, Equatable, Identifiable {
    public enum Role: String, Codable {
        case user, assistant
    }

    public let id: Int
    public let role: Role
    public var content: String
    public var images: [Data] = []

    public init(id: Int, role: Role, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }

    static let imagePlaceholder = "[image]"

    public var isEmpty: Bool { content.isEmpty && images.isEmpty }

    var contentForModel: String {
        content.isEmpty && !images.isEmpty ? Self.imagePlaceholder : content
    }

    public mutating func append(_ part: AnswerPart) {
        switch part {
        case .text(let text): content += text
        case .image(let data): images.append(data)
        }
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

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(role, forKey: .role)
        try c.encode(contentForModel, forKey: .content)
    }
}
