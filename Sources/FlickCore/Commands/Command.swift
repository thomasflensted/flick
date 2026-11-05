public enum Command: Hashable {
    case caffeinate
    case decaffeinate
    case caffeinateFor(minutes: Int)
    case loremSentence
    case loremParagraph

    public static func available(isCaffeinated: Bool) -> [Command] {
        [isCaffeinated ? .decaffeinate : .caffeinate, .loremSentence, .loremParagraph]
    }

    public var id: String {
        switch self {
        case .caffeinate: return "caffeinate"
        case .decaffeinate: return "decaffeinate"
        case .caffeinateFor: return "caffeinateFor"
        case .loremSentence: return "loremSentence"
        case .loremParagraph: return "loremParagraph"
        }
    }

    public var title: String {
        switch self {
        case .caffeinate: return "Caffeinate"
        case .decaffeinate: return "Decaffeinate"
        case .caffeinateFor(let minutes): return "Caffeinate for \(DurationText.format(minutes: minutes))"
        case .loremSentence: return "Lorem Ipsum: Generate Sentence"
        case .loremParagraph: return "Lorem Ipsum: Generate Paragraph"
        }
    }

    public var subtitle: String {
        switch self {
        case .caffeinate: return "Keep your Mac awake"
        case .decaffeinate: return "Let your Mac sleep again"
        case .caffeinateFor: return "Keep your Mac awake, then let it sleep"
        case .loremSentence, .loremParagraph: return "Paste placeholder text"
        }
    }

    public var symbol: String {
        switch self {
        case .caffeinate, .caffeinateFor: return "cup.and.saucer.fill"
        case .decaffeinate: return "cup.and.saucer"
        case .loremSentence: return "text.alignleft"
        case .loremParagraph: return "text.justify.left"
        }
    }
}
