public struct ModeShortcut: Equatable {
    public let key: String
    public let label: String
    public let action: Action

    public enum Action {
        case swapLanguages
        case newChat
        case switchModel
    }

    public var hint: String { "⌘\(key.uppercased())" }
}
