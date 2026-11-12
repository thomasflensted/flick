import Foundation
import Testing
@testable import FlickCore

struct FilesTests {
    private let report = FoundFile(path: "/Users/me/Documents/Report.pdf")
    private let reports = FoundFile(path: "/Users/me/Archive/Old reports")

    @Test func showsTheContainingFolderRelativeToHome() {
        #expect(report.details(home: "/Users/me") == "~/Documents")
        #expect(report.details(home: "/Users/other") == "/Users/me/Documents")
    }

    @Test func ranksNamesStartingWithTheQueryFirst() {
        #expect(FileResults.results(for: "rep", in: [reports, report]).map(\.title) == ["Report.pdf", "Old reports"])
    }

    @Test func keepsAnExactNameAmongManyLooserMatches() {
        let many = (0..<100).map { FoundFile(path: "/tmp/old downloads \($0).zip") } + [FoundFile(path: "/Users/me/Downloads")]
        #expect(FileResults.results(for: "downloads", in: many).first?.title == "Downloads")
    }

    @Test func showsOnlyTheBestMatches() {
        let many = (0..<100).map { FoundFile(path: "/tmp/report \($0)") }
        #expect(FileResults.results(for: "report", in: many).count == FileResults.limit)
    }

    @Test func asksForInputWhenTheQueryIsEmpty() {
        #expect(FileResults.results(for: " ", in: [report]) == [.hint("Type to search files and folders")])
    }

    @Test func isOpenedFromTheCommandList() {
        let search = SearchResults(links: [], apps: [], usage: [:])
        #expect(search.results(for: "search files").first?.kind == .mode(.files))
    }
}
