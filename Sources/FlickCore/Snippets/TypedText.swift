public struct TypedText {
    public static let limit = 64
    public private(set) var text = ""

    public init() {}

    public mutating func type(_ characters: String) {
        text = String((text + characters).suffix(Self.limit))
    }

    public mutating func deleteBackward() {
        text = String(text.dropLast())
    }

    public mutating func reset() {
        text = ""
    }
}
