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

struct FaviconTests {
    @Test func triesParentDomainsDownToTheSiteItself() {
        #expect(Favicon.hosts(for: "dashboard.render.com") == ["dashboard.render.com", "render.com"])
        #expect(Favicon.hosts(for: "a.b.example.com") == ["a.b.example.com", "b.example.com", "example.com"])
        #expect(Favicon.hosts(for: "github.com") == ["github.com"])
    }

    @Test func tinyIconsAreNotSharpEnough() {
        #expect(!Favicon.isSharp(pixelWidth: 16))
        #expect(Favicon.isSharp(pixelWidth: 32))
    }
}
