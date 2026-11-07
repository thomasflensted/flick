public enum Delivery {
    case paste
    case copy
}

extension ResultKind {
    public var producesText: Bool {
        switch self {
        case .command(let command): return command.producesText
        case .emoji, .snippet, .clip, .conversion, .translation: return true
        case .quicklink, .app, .url, .google, .askAI, .mode, .server, .model, .hint, .message: return false
        }
    }
}

extension Command {
    public var producesText: Bool {
        switch self {
        case .loremSentence, .loremParagraph: return true
        case .keepAwake, .keepAwakeFor, .allowSleep: return false
        }
    }
}
