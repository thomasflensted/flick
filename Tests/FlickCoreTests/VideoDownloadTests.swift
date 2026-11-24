import Foundation
import Testing
@testable import FlickCore

struct VideoDownloadTests {
    @Test(arguments: [
        "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "https://youtu.be/dQw4w9WgXcQ",
        "https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=10",
        "https://www.youtube.com/shorts/abc123",
    ])
    func recognizesVideoLinks(_ link: String) {
        #expect(VideoDownload.isYouTubeVideo(URL(string: link)!))
    }

    @Test(arguments: [
        "https://www.youtube.com",
        "https://youtu.be/",
        "https://www.youtube.com/@somechannel",
        "https://vimeo.com/watch?v=1",
    ])
    func ignoresOtherLinks(_ link: String) {
        #expect(!VideoDownload.isYouTubeVideo(URL(string: link)!))
    }

    @Test func parsesProgressLines() {
        #expect(VideoDownload.parse("progress 41.50216474986172") == .progress(percent: 41))
        #expect(VideoDownload.parse("progress 100.0") == .progress(percent: 100))
        #expect(VideoDownload.parse("progress NA") == nil)
    }

    @Test func parsesDownloadedFileLines() {
        #expect(VideoDownload.parse("/Users/me/Downloads/My Video.mp4") == .file(URL(fileURLWithPath: "/Users/me/Downloads/My Video.mp4")))
        #expect(VideoDownload.parse("") == nil)
    }

    @Test func offersDownloadForYouTubeLinks() {
        let search = SearchResults(links: [], apps: [], usage: [:])
        let link = "https://youtu.be/dQw4w9WgXcQ"
        #expect(search.results(for: link).contains { $0.kind == .command(.downloadVideo(URL(string: link)!)) })
        #expect(!search.results(for: "https://github.com").contains { $0.title == "Download Video" })
    }
}
