public struct Emoji: Hashable {
    public let character: String
    public let name: String

    public init(character: String, name: String) {
        self.character = character
        self.name = name
    }
}
