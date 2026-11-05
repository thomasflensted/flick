import Testing
@testable import FlickCore

struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct LoremIpsumTests {
    @Test(arguments: 0..<20)
    func sentenceIsCapitalisedWithFullStop(seed: UInt64) {
        var generator = SeededGenerator(state: seed)
        let sentence = LoremIpsum.sentence(using: &generator)
        #expect(sentence.first?.isUppercase == true)
        #expect(sentence.hasSuffix("."))
        #expect(LoremIpsum.wordsPerSentence.contains(sentence.split(separator: " ").count))
    }

    @Test(arguments: 0..<20)
    func paragraphHasSeveralSentences(seed: UInt64) {
        var generator = SeededGenerator(state: seed)
        let sentences = LoremIpsum.paragraph(using: &generator).split(separator: ".").count
        #expect(LoremIpsum.sentencesPerParagraph.contains(sentences))
    }
}
