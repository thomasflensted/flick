public enum Command: Hashable {
    case keepAwake
    case allowSleep
    case keepAwakeFor(minutes: Int)
    case loremSentence
    case loremParagraph
    case tile(WindowTile)

    public static func available(isKeepingAwake: Bool) -> [Command] {
        [isKeepingAwake ? .allowSleep : .keepAwake, .loremSentence, .loremParagraph] + WindowTile.allCases.map(Command.tile)
    }

    public var id: String {
        switch self {
        case .keepAwake: return "keepAwake"
        case .allowSleep: return "allowSleep"
        case .keepAwakeFor: return "keepAwakeFor"
        case .loremSentence: return "loremSentence"
        case .loremParagraph: return "loremParagraph"
        case .tile(let tile): return "tile.\(tile.id)"
        }
    }

    public var title: String {
        switch self {
        case .keepAwake: return "Keep Awake"
        case .allowSleep: return "Allow Sleep"
        case .keepAwakeFor(let minutes): return "Keep Awake for \(DurationText.format(minutes: minutes))"
        case .loremSentence: return "Lorem Ipsum: Generate Sentence"
        case .loremParagraph: return "Lorem Ipsum: Generate Paragraph"
        case .tile(let tile): return tile.title
        }
    }

    public var aliases: [String] {
        switch self {
        case .keepAwake, .keepAwakeFor: return ["Caffeinate"]
        case .allowSleep: return ["Decaffeinate"]
        case .loremSentence, .loremParagraph: return []
        case .tile(let tile): return tile.aliases
        }
    }

    public var subtitle: String {
        switch self {
        case .keepAwake: return "Stop your Mac from sleeping"
        case .allowSleep: return "Let your Mac sleep again"
        case .keepAwakeFor: return "Stop your Mac from sleeping, then let it sleep"
        case .loremSentence, .loremParagraph: return "Paste placeholder text"
        case .tile(let tile): return tile.subtitle
        }
    }

    public var symbol: String {
        switch self {
        case .keepAwake, .keepAwakeFor: return "sun.max.fill"
        case .allowSleep: return "moon.zzz.fill"
        case .loremSentence: return "text.alignleft"
        case .loremParagraph: return "text.justify.left"
        case .tile(let tile): return tile.symbol
        }
    }
}
