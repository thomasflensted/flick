import FlickCore
import SwiftUI

struct QuicklinkEditor: View {
    @State var link: Quicklink
    var onSave: (Quicklink) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Form {
                TextField("Name", text: $link.name)
                TextField("Link", text: $link.link)
                TextField("Keyword", text: $link.keyword.orEmpty)
                HStack {
                    TextField("Open With", text: $link.openWith.orEmpty, prompt: Text("Default app"))
                    Button("Choose…") { if let app = chooseApp() { link.openWith = app } }
                }
            }
            Text("Use {argument} in the link for text typed after the name or keyword, e.g. https://github.com/search?q={argument}")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") { onSave(link); dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(link.name.isEmpty || link.link.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 520)
    }

    private func chooseApp() -> String? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return Bundle(url: url)?.bundleIdentifier ?? url.path
    }
}
