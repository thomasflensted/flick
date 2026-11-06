import AppKit
import FlickCore
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
                Button(action: save) {
                    Image(systemName: saved ? "checkmark.circle" : "arrow.down.circle")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Save to Downloads")
            }
        }
    }

    private func save() {
        guard let png = NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:]) else { return }
        let url = URL.downloadsDirectory.appending(path: "\(NanoID.make()).png")
        saved = (try? png.write(to: url)) != nil
    }
}
