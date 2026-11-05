import Foundation
import Testing
@testable import FlickCore

struct URLTextTests {
    @Test func addsHTTPSToBareDomains() {
        #expect(URLText.url(from: "reddit.com")?.absoluteString == "https://reddit.com")
    }

    @Test func keepsSchemes() {
        #expect(URLText.url(from: "http://localhost:3000")?.absoluteString == "http://localhost:3000")
        #expect(URLText.url(from: "slack://open")?.scheme == "slack")
    }

    @Test func expandsHomePaths() {
        #expect(URLText.url(from: "~/Developer")?.path == NSHomeDirectory() + "/Developer")
    }

    @Test(arguments: ["reddit.com", "https://github.com/x", "news.ycombinator.com"])
    func webAddresses(text: String) {
        #expect(URLText.looksLikeWebAddress(text))
    }

    @Test(arguments: ["slack", "node.js tutorial"])
    func notWebAddresses(text: String) {
        #expect(!URLText.looksLikeWebAddress(text))
    }
}
