import SwiftUI

struct FaviconView<Placeholder: View>: View {
    let host: String
    @ViewBuilder let placeholder: () -> Placeholder
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image { Image(nsImage: image).resizable().interpolation(.high) } else { placeholder() }
        }
        .task(id: host) { image = await FaviconCache.shared.icon(for: host) }
    }
}
