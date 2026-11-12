import Foundation
import Testing
@testable import FlickCore

struct FilesTests {
    private let report = FoundFile(name: "Report.pdf", url: URL(fileURLWithPath: "/Users/me/Documents/Report.pdf"))
    private let reports = FoundFile(name: "Old reports", url: URL(fileURLWithPath: "/Users/me/Archive/Old reports"))

    @Test func showsTheContainingFolderRelativeToHome() {
        #expect(report.details(home: "/Users/me") == "~/Documents")
        #expect(report.details(home: "/Users/other") == "/Users/me/Documents")
    }

    @Test func ranksNamesStartingWithTheQueryFirst() {
        #expect(FileResults.results(for: "rep", in: [reports, report]).map(\.title) == ["Report.pdf", "Old reports"])
    }

    @Test func asksForInputWhenTheQueryIsEmpty() {
        #expect(FileResults.results(for: " ", in: [report]) == [.hint("Type to search files and folders")])
    }

    @Test func isOpenedFromTheCommandList() {
        let search = SearchResults(links: [], apps: [], usage: [:])
        #expect(search.results(for: "search files").first?.kind == .mode(.files))
    }
}
