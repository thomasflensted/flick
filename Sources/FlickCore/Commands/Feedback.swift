public struct Feedback: Equatable {
    public let text: String
    public let symbol: String

    public static let copied = Feedback(text: "Copied to clipboard", symbol: "doc.on.clipboard.fill")
    public static let sleepAllowed = Feedback(text: "Your Mac can sleep again", symbol: "moon.zzz.fill")

    public static func after(_ kind: ResultKind, delivered: Delivery?) -> Feedback? {
        if delivered == .copy { return .copied }
        guard case .command(let command) = kind else { return nil }
        switch command {
        case .keepAwake: return Feedback(text: "Your Mac will stay awake", symbol: "sun.max.fill")
        case .keepAwakeFor(let minutes):
            return Feedback(text: "Your Mac will stay awake for \(DurationText.format(minutes: minutes))", symbol: "sun.max.fill")
        case .allowSleep: return .sleepAllowed
        case .loremSentence, .loremParagraph: return nil
        }
    }
}
