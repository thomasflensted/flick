public enum LoremIpsum {
    static let words = """
    lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore \
    magna aliqua enim ad minim veniam quis nostrud exercitation ullamco laboris nisi aliquip ex ea commodo \
    consequat duis aute irure in reprehenderit voluptate velit esse cillum fugiat nulla pariatur excepteur sint \
    occaecat cupidatat non proident sunt culpa qui officia deserunt mollit anim id est laborum
    """.split(separator: " ").map(String.init)

    static let wordsPerSentence = 8...14
    static let sentencesPerParagraph = 4...7

    public static func sentence<G: RandomNumberGenerator>(using generator: inout G) -> String {
        let count = Int.random(in: wordsPerSentence, using: &generator)
        let text = (0..<count).map { _ in words.randomElement(using: &generator)! }.joined(separator: " ")
        return text.prefix(1).uppercased() + text.dropFirst() + "."
    }

    public static func paragraph<G: RandomNumberGenerator>(using generator: inout G) -> String {
        let count = Int.random(in: sentencesPerParagraph, using: &generator)
        return (0..<count).map { _ in sentence(using: &generator) }.joined(separator: " ")
    }

    public static func sentence() -> String {
        var generator = SystemRandomNumberGenerator()
        return sentence(using: &generator)
    }

    public static func paragraph() -> String {
        var generator = SystemRandomNumberGenerator()
        return paragraph(using: &generator)
    }
}
