public enum EmojiCatalog {
    static let smileysFirst: [ClosedRange<UInt32>] = [
        0x1F600...0x1F64F, 0x1F900...0x1FAFF, 0x1F300...0x1F5FF, 0x1F680...0x1F6FF,
        0x2190...0x2BFF, 0x1F000...0x1F2FF, 0x1F650...0x1F67F, 0x1F700...0x1F8FF,
    ]
    static let variationSelector = "\u{FE0F}"

    public static let all: [Emoji] = smileysFirst.flatMap { $0.compactMap(emoji(for:)) }

    public static func results(for query: String, usage: [String: Int]) -> [ResultItem] {
        Ranker(usage: usage).rank(all, query: query, text: \.name, key: UsageKey.emoji).map(ResultItem.emoji)
    }

    static func emoji(for value: UInt32) -> Emoji? {
        guard let scalar = Unicode.Scalar(value), isStandaloneEmoji(scalar), let name = scalar.properties.name else { return nil }
        let character = String(scalar) + (scalar.properties.isEmojiPresentation ? "" : variationSelector)
        return Emoji(character: character, name: name.lowercased())
    }

    static func isStandaloneEmoji(_ scalar: Unicode.Scalar) -> Bool {
        let properties = scalar.properties
        return properties.isEmoji && !properties.isEmojiModifier && !isRegionalIndicator(scalar)
    }

    private static func isRegionalIndicator(_ scalar: Unicode.Scalar) -> Bool {
        (0x1F1E6...0x1F1FF).contains(scalar.value)
    }
}
