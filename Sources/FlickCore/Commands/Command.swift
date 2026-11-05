public enum Command: Hashable {
    case caffeinate
    case decaffeinate
    case caffeinateFor(minutes: Int)

    public static func available(isCaffeinated: Bool) -> [Command] {
        [isCaffeinated ? .decaffeinate : .caffeinate]
    }

    public var id: String {
        switch self {
        case .caffeinate: return "caffeinate"
        case .decaffeinate: return "decaffeinate"
        case .caffeinateFor: return "caffeinateFor"
        }
    }

    public var title: String {
        switch self {
        case .caffeinate: return "Caffeinate"
        case .decaffeinate: return "Decaffeinate"
        case .caffeinateFor(let minutes): return "Caffeinate for \(DurationText.format(minutes: minutes))"
        }
    }

    public var subtitle: String {
        switch self {
        case .caffeinate: return "Keep your Mac awake"
        case .decaffeinate: return "Let your Mac sleep again"
        case .caffeinateFor: return "Keep your Mac awake, then let it sleep"
        }
    }

    public var symbol: String {
        switch self {
        case .caffeinate, .caffeinateFor: return "cup.and.saucer.fill"
        case .decaffeinate: return "cup.and.saucer"
        }
    }
}
