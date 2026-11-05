import Testing
@testable import FlickCore

struct SnippetTests {
    @Test func expandsEachIdSeparately() {
        var count = 0
        let expanded = SnippetTemplate.expand("a+{id}@x.com {id}") { count += 1; return "id\(count)" }
        #expect(expanded == "a+id1@x.com id2")
    }

    @Test func textWithoutPlaceholdersIsUnchanged() {
        #expect(SnippetTemplate.expand("const f = () => {}", id: { "x" }) == "const f = () => {}")
    }

    @Test(arguments: 0..<10)
    func nanoIDHasEightURLSafeCharacters(seed: UInt64) {
        var generator = SeededGenerator(state: seed)
        let id = NanoID.make(using: &generator)
        #expect(id.count == 8)
        #expect(id.allSatisfy { NanoID.alphabet.contains($0) })
    }

    @Test func findsSnippetByKeyword() {
        let snippets = [Snippet(name: "Hotmail", text: "me@live.com", keyword: "@@h"), Snippet(name: "Gmail", text: "me@gmail.com", keyword: "@@g")]
        #expect(SnippetSearch.results(for: "@@g", snippets: snippets, usage: [:]).first?.title == "Gmail")
    }

    @Test func previewIsOneLine() {
        #expect(ResultItem.snippet(Snippet(name: "Two lines", text: "a\nb")).subtitle == "a b")
    }

    @Test func snippetsCanBeCopied() {
        #expect(ResultKind.snippet(Snippet(name: "x", text: "y")).producesText)
    }
}
