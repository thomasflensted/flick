import AppKit
import SwiftUI

struct GeneratedImage: View {
    let data: Data
    @State private var saved = false

    var body: some View {
        if let image = NSImage(data: data) {
            HStack(spacing: 8) {
                Image(nsImage: image)
                    .resizable().scaledToFit()
                    .frame(maxWidth: 360, maxHeight: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Button { saved = ImageDownloads.save(data) } label: {
                    Image(systemName: saved ? "checkmark.circle" : "arrow.down.circle")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Save to Downloads")
            }
        }
    }
}
