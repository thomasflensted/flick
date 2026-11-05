import Foundation
import Testing
@testable import FlickCore

struct RaycastExportTests {
    @Test func readsQuicklinks() throws {
        let json = """
        {"raycast_version": "1.0",
         "builtin_package_quicklinks": {"enableQuickSearch": false, "quicklinks": [
           {"uuid": "8AED846F-F8C3-45F9-B5B5-290F00177849", "name": "Search Google",
            "url": "https://google.com/search?q={argument}", "openCount": 929, "isEnabled": true}
         ]}}
        """
        let links = try RaycastExport.quicklinks(fromJSON: Data(json.utf8))
        #expect(links == [Quicklink(id: UUID(uuidString: "8AED846F-F8C3-45F9-B5B5-290F00177849")!,
                                    name: "Search Google", link: "https://google.com/search?q={argument}")])
    }

    @Test func rejectsFilesWithoutQuicklinks() {
        #expect(throws: (any Error).self) { try RaycastExport.quicklinks(fromJSON: Data("{}".utf8)) }
    }
}
