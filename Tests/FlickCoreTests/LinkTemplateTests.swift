import Testing
@testable import FlickCore

struct LinkTemplateTests {
    @Test func plainLinkTakesNoArgument() {
        #expect(!LinkTemplate.takesArgument("https://github.com"))
    }

    @Test func detectsArgument() {
        #expect(LinkTemplate.takesArgument("https://google.com/search?q={argument}"))
        #expect(LinkTemplate.takesArgument(#"https://x.com/?q={argument name="Term"}"#))
    }

    @Test func encodesArgumentInURLs() {
        #expect(LinkTemplate.resolve("https://google.com/search?q={argument}", argument: "fish & chips?")
            == "https://google.com/search?q=fish%20%26%20chips%3F")
    }

    @Test func leavesArgumentUnencodedInPaths() {
        #expect(LinkTemplate.resolve("~/Developer/{argument}", argument: "my app") == "~/Developer/my app")
    }

    @Test func usesDefaultWhenArgumentIsEmpty() {
        #expect(LinkTemplate.resolve(#"https://x.com/{argument default="home"}"#, argument: "") == "https://x.com/home")
    }

    @Test func labelComesFromName() {
        #expect(LinkTemplate.argumentLabel(#"https://x.com/?q={argument name="Term"}"#) == "Term")
        #expect(LinkTemplate.argumentLabel("https://x.com/?q={argument}") == "Query")
    }
}
