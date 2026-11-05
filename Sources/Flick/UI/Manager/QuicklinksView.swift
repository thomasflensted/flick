import FlickCore
import SwiftUI

struct QuicklinksView: View {
    @ObservedObject var store: QuicklinkStore
    var onImport: () -> Void
    @State private var selection = Set<UUID>()
    @State private var editing: Quicklink?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let error = store.loadError {
                Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
            table
            toolbar
        }
        .padding()
        .frame(minWidth: 720, minHeight: 420)
        .sheet(item: $editing) { link in
            QuicklinkEditor(link: link) { store.upsert($0) }
        }
    }

    private var table: some View {
        Table(store.links, selection: $selection) {
            TableColumn("Name", value: \.name)
            TableColumn("Keyword") { Text($0.keyword ?? "").foregroundStyle(.secondary) }.width(70)
            TableColumn("Link", value: \.link)
            TableColumn("Open With") { Text(appName(for: $0)).foregroundStyle(.secondary) }.width(110)
        }
        .contextMenu(forSelectionType: UUID.self) { ids in
            Button("Edit") { edit(ids) }
            Button("Delete", role: .destructive) { store.delete(ids: ids) }
        } primaryAction: { ids in
            edit(ids)
        }
    }

    private var toolbar: some View {
        HStack {
            Button { editing = Quicklink(name: "", link: "") } label: { Image(systemName: "plus") }
            Button { store.delete(ids: selection); selection = [] } label: { Image(systemName: "minus") }
                .disabled(selection.isEmpty)
            Text("\(store.links.count) quicklinks").foregroundStyle(.secondary).font(.caption)
            Spacer()
            Button("Import from Raycast…", action: onImport)
            Button("Show JSON File") { NSWorkspace.shared.activateFileViewerSelecting([AppSupport.quicklinksFile]) }
        }
    }

    private func edit(_ ids: Set<UUID>) {
        editing = store.links.first { ids.contains($0.id) }
    }

    private func appName(for link: Quicklink) -> String {
        Launcher.appURL(for: link.openWith).map { FileManager.default.displayName(atPath: $0.path) } ?? "Default"
    }
}
