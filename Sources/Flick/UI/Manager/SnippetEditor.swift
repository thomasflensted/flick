import FlickCore
import SwiftUI

struct SnippetEditor: View {
    @State var snippet: Snippet
    var onSave: (Snippet) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Form {
                TextField("Name", text: $snippet.name)
                TextField("Keyword", text: $snippet.keyword.orEmpty, prompt: Text("e.g. @@h"))
            }
            TextEditor(text: $snippet.text)
                .font(.system(size: 13, design: .monospaced))
                .frame(height: 140)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.15)))
            Text("Type the keyword in any app to insert the text. Use {id} for a random 8-character id, e.g. test+{id}@example.com")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") { onSave(snippet); dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(snippet.name.isEmpty || snippet.text.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 520)
    }
}
