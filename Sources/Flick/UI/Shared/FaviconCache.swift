import AppKit
import FlickCore

@MainActor
final class FaviconCache {
    static let shared = FaviconCache()
    private var icons: [String: NSImage?] = [:]

    func icon(for host: String) async -> NSImage? {
        if let cached = icons[host] { return cached }
        var found: NSImage?
        for candidate in Favicon.hosts(for: host) {
            found = await fetch(candidate)
            if found != nil { break }
        }
        icons[host] = found
        return found
    }

    private func fetch(_ host: String) async -> NSImage? {
        guard let (data, _) = try? await URLSession.shared.data(from: Favicon.url(for: host)),
              let image = NSImage(data: data), let width = image.representations.first?.pixelsWide,
              Favicon.isSharp(pixelWidth: width) else { return nil }
        return image
    }
}
