import Foundation
import Testing
@testable import FlickCore

struct QuicklinkTests {
    @Test func decodesWithoutIdOrOptionalFields() throws {
        let links = try JSONDecoder().decode([Quicklink].self, from: Data(#"[{"name": "GitHub", "link": "https://github.com", "keyword": ""}]"#.utf8))
        #expect(links.first?.name == "GitHub")
        #expect(links.first?.keyword == nil)
    }

    @Test func duplicatesBySameIdOrSameNameAndLink() {
        let link = Quicklink(name: "GitHub", link: "https://github.com")
        #expect(link.isDuplicate(of: Quicklink(id: link.id, name: "Other", link: "https://other.com")))
        #expect(link.isDuplicate(of: Quicklink(name: "GitHub", link: "https://github.com")))
        #expect(!link.isDuplicate(of: Quicklink(name: "GitHub", link: "https://github.com/pulls")))
    }

    @Test func triggerPrefersKeyword() {
        #expect(Quicklink(name: "Search Google", link: "", keyword: "g").trigger == "g")
        #expect(Quicklink(name: "Search Google", link: "").trigger == "Search Google")
    }

    @Test func webHostForWebLinksOnly() {
        #expect(Quicklink(name: "", link: "https://google.com/search?q={argument}").webHost == "google.com")
        #expect(Quicklink(name: "", link: "reddit.com").webHost == "reddit.com")
        #expect(Quicklink(name: "", link: "slack://open").webHost == nil)
        #expect(Quicklink(name: "", link: "~/Developer").webHost == nil)
    }
}
