import Foundation
import Testing
@testable import FlickCore

struct RaycastExportTests {
    @Test func readsQuicklinksAndSnippets() throws {
        let json = """
        {"raycast_version": "1.0",
         "builtin_package_quicklinks": {"enableQuickSearch": false, "quicklinks": [
           {"uuid": "8AED846F-F8C3-45F9-B5B5-290F00177849", "name": "Search Google",
            "url": "https://google.com/search?q={argument}", "openCount": 929, "isEnabled": true}
         ]},
         "builtin_package_snippets": {"packSnippets": [], "snippets": [
           {"name": "Greeting", "text": "Hello there", "alias": "@hi", "category": "text"},
           {"name": "No alias", "text": "test+{uuid}@x.com"}
         ]}}
        """
        let contents = try RaycastExport.contents(fromJSON: Data(json.utf8))
        #expect(contents.quicklinks == [Quicklink(id: UUID(uuidString: "8AED846F-F8C3-45F9-B5B5-290F00177849")!,
                                                  name: "Search Google", link: "https://google.com/search?q={argument}")])
        #expect(contents.snippets.map(\.name) == ["Greeting", "No alias"])
        #expect(contents.snippets.map(\.keyword) == ["@hi", nil])
        #expect(contents.snippets.last?.text == "test+{id}@x.com")
    }

    @Test func rejectsFilesWithNothingToImport() {
        #expect(throws: RaycastExport.NothingToImport.self) { try RaycastExport.contents(fromJSON: Data("{}".utf8)) }
    }
}
