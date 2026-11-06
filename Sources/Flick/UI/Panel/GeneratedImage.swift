import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct GeneratedImage: View {
    let data: Data

    var body: some View {
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable().scaledToFit()
                .frame(maxWidth: 360, maxHeight: 360)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topTrailing) { saveButton }
                .contextMenu { Button("Save Image…", action: save) }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Image(systemName: "square.and.arrow.down")
                .padding(6)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .help("Save Image…")
        .padding(6)
    }

    private func save() {
        guard let png = NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:]) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Image.png"
        NSApp.activate()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? png.write(to: url)
    }
}
