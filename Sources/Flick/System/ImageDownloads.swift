import AppKit
import FlickCore

enum ImageDownloads {
    static func save(_ data: Data) -> Bool {
        guard let png = pngData(from: data) else { return false }
        return (try? png.write(to: newFileURL())) != nil
    }

    private static func pngData(from data: Data) -> Data? {
        NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:])
    }

    private static func newFileURL() -> URL {
        URL.downloadsDirectory.appending(path: "\(NanoID.make()).png")
    }
}
