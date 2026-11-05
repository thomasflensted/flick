import Testing
@testable import FlickCore

struct SnippetExpansionTests {
    let hotmail = Snippet(name: "Hotmail", text: "me@live.com", keyword: "@@h")
    let name = Snippet(name: "thomasflensted", text: "thomasflensted", keyword: "tf")
    var snippets: [Snippet] { [hotmail, name, Snippet(name: "No keyword", text: "x")] }

    @Test func matchesKeywordAtStartOfText() {
        #expect(SnippetExpansion.match(in: "@@h", snippets: snippets) == hotmail)
    }

    @Test func matchesKeywordAfterSpace() {
        #expect(SnippetExpansion.match(in: "my mail is @@h", snippets: snippets) == hotmail)
        #expect(SnippetExpansion.match(in: "hi\ntf", snippets: snippets) == name)
    }

    @Test func ignoresKeywordInsideAWord() {
        #expect(SnippetExpansion.match(in: "outf", snippets: snippets) == nil)
        #expect(SnippetExpansion.match(in: "outtf", snippets: snippets) == nil)
    }

    @Test func ignoresPartialKeyword() {
        #expect(SnippetExpansion.match(in: "@@", snippets: snippets) == nil)
    }

    @Test func prefersLongestKeyword() {
        let long = Snippet(name: "Long", text: "y", keyword: "a b")
        let short = Snippet(name: "Short", text: "z", keyword: "b")
        #expect(SnippetExpansion.match(in: "a b", snippets: [short, long]) == long)
    }
}

struct TypedTextTests {
    @Test func keepsOnlyRecentCharacters() {
        var typed = TypedText()
        typed.type(String(repeating: "x", count: 100) + "@@h")
        #expect(typed.text.count == TypedText.limit)
        #expect(typed.text.hasSuffix("@@h"))
    }

    @Test func deletesAndResets() {
        var typed = TypedText()
        typed.type("abc")
        typed.deleteBackward()
        #expect(typed.text == "ab")
        typed.reset()
        #expect(typed.text.isEmpty)
    }
}
