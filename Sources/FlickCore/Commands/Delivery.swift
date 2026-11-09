import Foundation

public enum Delivery {
    case paste
    case copy
}

extension ResultKind {
    public func text(locale: Locale) -> String? {
        switch self {
        case .command(let command): return command.text
        case .emoji(let emoji): return emoji.character
        case .snippet(let snippet): return snippet.expanded()
        case .clip(let entry): return entry.text
        case .conversion(let conversion): return conversion.plainValue(locale)
        case .time(let time): return time.time(locale)
        case .translation(let translation): return translation.text
        case .quicklink, .app, .url, .google, .askAI, .mode, .server, .model, .drive, .pullRequest, .weather, .hint, .quicklinksError: return nil
        }
    }

    public var producesText: Bool {
        text(locale: .current) != nil
    }
}

extension Command {
    public var text: String? {
        switch self {
        case .loremSentence: return LoremIpsum.sentence()
        case .loremParagraph: return LoremIpsum.paragraph()
        case .keepAwake, .keepAwakeFor, .allowSleep, .tile, .toggleFullScreen: return nil
        }
    }
}
