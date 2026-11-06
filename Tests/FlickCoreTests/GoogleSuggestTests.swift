import Foundation
import Testing
@testable import FlickCore

struct GoogleSuggestTests {
    @Test func parsesSuggestionsWithoutTheTypedQuery() throws {
        let json = #"["swift async",["Swift Async","swift async await","swift asyncstream"],[],{}]"#
        #expect(try GoogleSuggest.parse(Data(json.utf8), query: "swift async") == ["swift async await", "swift asyncstream"])
    }

    @Test func keepsAtMostFiveSuggestions() throws {
        let json = #"["a",["a1","a2","a3","a4","a5","a6"]]"#
        #expect(try GoogleSuggest.parse(Data(json.utf8), query: "a").count == 5)
    }

    @Test func rejectsUnexpectedResponse() {
        #expect(throws: (any Error).self) { try GoogleSuggest.parse(Data("{}".utf8), query: "a") }
    }
}

struct GoogleSuggestLinkTests {
    @Test func supportsGoogleSearchQuicklinks() {
        #expect(GoogleSuggest.supports(Quicklink(name: "G", link: "https://google.com/search?q={argument}")))
        #expect(GoogleSuggest.supports(Quicklink(name: "G", link: "https://www.google.dk/search?q={argument}")))
        #expect(!GoogleSuggest.supports(Quicklink(name: "Maps", link: "https://www.google.com/maps?q={argument}")))
        #expect(!GoogleSuggest.supports(Quicklink(name: "GitHub", link: "https://github.com/search?q={argument}")))
        #expect(!GoogleSuggest.supports(Quicklink(name: "G", link: "https://google.com/search")))
    }

    @Test func suggestionsRunTheQuicklinkWithTheSuggestion() {
        let ql = Quicklink(name: "Search Google", link: "https://google.com/search?q={argument}")
        let results = GoogleSuggest.results(for: ql, suggestions: ["swift async await"])
        #expect(results.map(\.kind) == [.quicklink(ql, argument: nil), .quicklink(ql, argument: "swift async await")])
    }
}
