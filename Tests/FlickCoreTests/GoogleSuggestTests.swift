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

struct GoogleSuggestResultsTests {
    @Test func suggestionsRunGoogleSearchWithTheSuggestion() {
        let results = GoogleSuggest.results(suggestions: ["swift async await"])
        #expect(results.map(\.kind) == [.quicklink(.googleSearch, argument: nil), .quicklink(.googleSearch, argument: "swift async await")])
    }
}
