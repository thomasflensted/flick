import FlickCore
import SwiftUI

struct SnippetsView: View {
    @ObservedObject var store: SnippetStore
    @State private var selection = Set<UUID>()
    @State private var editing: Snippet?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let error = store.loadError {
                Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
            Table(store.items, selection: $selection) {
                TableColumn("Name", value: \.name)
                TableColumn("Keyword") { Text($0.keyword ?? "").foregroundStyle(.secondary) }.width(90)
                TableColumn("Text") { Text($0.text).lineLimit(1).foregroundStyle(.secondary) }
            }
            .contextMenu(forSelectionType: UUID.self) { ids in
                Button("Edit") { edit(ids) }
                Button("Delete", role: .destructive) { store.delete(ids: ids) }
            } primaryAction: { ids in
                edit(ids)
            }
            HStack {
                Button { editing = Snippet(name: "", text: "") } label: { Image(systemName: "plus") }
                Button { store.delete(ids: selection); selection = [] } label: { Image(systemName: "minus") }
                    .disabled(selection.isEmpty)
                Text("\(store.items.count) snippets").foregroundStyle(.secondary).font(.caption)
                Spacer()
                Button("Show JSON File") { NSWorkspace.shared.activateFileViewerSelecting([store.fileURL]) }
            }
        }
        .padding()
        .frame(minWidth: 720, minHeight: 420)
        .sheet(item: $editing) { snippet in
            SnippetEditor(snippet: snippet) { store.upsert($0) }
        }
    }

    private func edit(_ ids: Set<UUID>) {
        editing = store.items.first { ids.contains($0.id) }
    }
}
