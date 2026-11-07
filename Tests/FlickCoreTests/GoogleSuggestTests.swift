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

struct SuggestionsTests {
    @Test func suggestionsRunTheQuicklinkWithTheSuggestion() {
        let results = Suggestions.results(["swift async await"], for: .googleSearch)
        #expect(results.map(\.kind) == [.quicklink(.googleSearch, argument: nil), .quicklink(.googleSearch, argument: "swift async await")])
    }

    @Test func placeSuggestionsIncludeTheirAddress() {
        #expect(Suggestions.placeText(title: "Tivoli", subtitle: "Vesterbrogade 3, Copenhagen") == "Tivoli, Vesterbrogade 3, Copenhagen")
        #expect(Suggestions.placeText(title: "Copenhagen", subtitle: "") == "Copenhagen")
    }

    @Test func googleMapsShipsWithAKeyword() {
        #expect(Quicklink.googleMaps.resolved(argument: "tivoli copenhagen") == "https://www.google.com/maps/search/?api=1&query=tivoli%20copenhagen")
        #expect(Quicklink.googleMaps.isTriggered(by: "gm"))
    }
}
