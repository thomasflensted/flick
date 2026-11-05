import AppKit
import SwiftUI

struct VisualEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .popover
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

final class IconCache {
    static let shared = IconCache()
    private var cache: [String: NSImage] = [:]
    func icon(path: String) -> NSImage {
        if let i = cache[path] { return i }
        let i = NSWorkspace.shared.icon(forFile: path)
        cache[path] = i
        return i
    }
}

struct ResultIcon: View {
    let kind: ResultKind
    var size: CGFloat = 26

    var body: some View {
        Group {
            switch kind {
            case .app(let a):
                Image(nsImage: IconCache.shared.icon(path: a.path)).resizable()
            case .quicklink(let ql, _):
                if let app = Opener.appURL(for: ql.openWith), ql.link.range(of: "^https?:", options: .regularExpression) == nil {
                    Image(nsImage: IconCache.shared.icon(path: app.path)).resizable()
                } else if let host = URL(string: ql.link.replacingOccurrences(of: #"\{[^}]*\}"#, with: "x", options: .regularExpression))?.host {
                    AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64")) { img in
                        img.resizable()
                    } placeholder: {
                        Image(systemName: "link").resizable().scaledToFit().padding(4).foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "link").resizable().scaledToFit().padding(4).foregroundStyle(.secondary)
                }
            case .url:
                Image(systemName: "safari").resizable().scaledToFit().padding(2).foregroundStyle(.blue)
            case .google:
                Image(systemName: "magnifyingglass").resizable().scaledToFit().padding(4).foregroundStyle(.secondary)
            case .message:
                Image(systemName: "exclamationmark.triangle.fill").resizable().scaledToFit().padding(3).foregroundStyle(.orange)
            }
        }
        .frame(width: size, height: size)
    }
}

private func textWidth(_ s: String, size: CGFloat, weight: NSFont.Weight = .regular) -> CGFloat {
    ceil((s as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: weight)]).width)
}

struct ResultRow: View {
    let item: ResultItem
    let selected: Bool
    var subtitleOverride: String? = nil

    private var badge: String {
        switch item.kind {
        case .quicklink: return "Quicklink"
        case .app: return "Application"
        case .url: return "URL"
        case .google: return "Web"
        case .message: return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ResultIcon(kind: item.kind)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(.system(size: 14, weight: .medium)).lineLimit(1)
                if case .app = item.kind {} else {
                    Text(subtitleOverride ?? item.subtitle).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                }
            }
            Spacer(minLength: 8)
            Text(badge).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(RoundedRectangle(cornerRadius: 8).fill(selected ? Color.primary.opacity(0.1) : .clear))
        .contentShape(Rectangle())
    }
}

struct SearchView: View {
    @ObservedObject var model: SearchModel
    @FocusState private var focus: Field?

    /// Quicklink whose inline argument field is shown in the search bar.
    private var pillLink: Quicklink? {
        guard let ql = model.argumentLink, !model.query.isEmpty || model.argumentTarget != nil else { return nil }
        return ql
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(model.results.enumerated()), id: \.element.id) { i, item in
                            ResultRow(item: item, selected: i == model.selected, subtitleOverride: subtitle(for: item))
                                .id(item.id)
                                .onTapGesture { model.activate(i) }
                        }
                    }
                    .padding(8)
                }
                .onChange(of: model.selected) { _, new in
                    if model.results.indices.contains(new) { proxy.scrollTo(model.results[new].id) }
                }
            }

            Divider()
            footer
        }
        .frame(width: 700, height: 460)
        .background(VisualEffect())
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.12)))
        .onChange(of: model.focusToken) { _, _ in focus = model.focusField }
        .onChange(of: focus) { _, new in
            // Keep the model in sync when the user clicks between the two fields.
            if new == .argument, model.argumentTarget == nil, let ql = pillLink { model.enterArgument(ql) }
            if new == .query, model.argumentTarget != nil { model.exitArgument() }
        }
        .onAppear { focus = .query }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.system(size: 18)).foregroundStyle(.secondary)
            TextField("Search apps, quicklinks, or Google…", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 20))
                .focused($focus, equals: .query)
                .frame(width: pillLink == nil ? nil : textWidth(model.query, size: 20) + 6, alignment: .leading)
            if let ql = pillLink {
                ResultIcon(kind: .quicklink(ql, argument: nil), size: 22)
                argumentField(ql)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
    }

    private func argumentField(_ ql: Quicklink) -> some View {
        let active = model.argumentTarget != nil
        let placeholder = ql.argumentPlaceholder
        let width = min(max(textWidth(placeholder, size: 16), textWidth(model.argument, size: 16)) + 22, 400)
        return TextField(placeholder, text: $model.argument)
            .textFieldStyle(.plain)
            .font(.system(size: 16))
            .focused($focus, equals: .argument)
            .padding(.horizontal, 10)
            .frame(width: width, height: 32)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(active ? 0.1 : 0.05)))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(active ? Color.accentColor.opacity(0.8) : Color.primary.opacity(0.2), lineWidth: active ? 1.5 : 1))
            .animation(.easeOut(duration: 0.12), value: active)
    }

    private func subtitle(for item: ResultItem) -> String? {
        guard let t = model.argumentTarget, case .quicklink(let ql, _) = item.kind, ql.id == t.id,
              !model.argument.isEmpty else { return nil }
        return ql.resolved(argument: model.argument)
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Spacer()
            hint("↵", "Open")
            hint("⇥", model.argumentTarget != nil ? "Back to search" : "Add query")
            hint("⌘,", "Manage quicklinks")
            hint("esc", "Close")
        }
        .padding(.horizontal, 14)
        .frame(height: 30)
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key).font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.08)))
            Text(label).font(.system(size: 11))
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Quicklink manager

struct QuicklinksView: View {
    @ObservedObject var store: QuicklinkStore
    var onImport: () -> Void
    @State private var selection = Set<UUID>()
    @State private var editing: Quicklink?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let err = store.loadError {
                Label(err, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
            Table(store.links, selection: $selection) {
                TableColumn("Name", value: \.name)
                TableColumn("Keyword") { Text($0.keyword ?? "").foregroundStyle(.secondary) }.width(70)
                TableColumn("Link", value: \.link)
                TableColumn("Open With") { ql in
                    Text(Opener.appURL(for: ql.openWith).map { FileManager.default.displayName(atPath: $0.path) } ?? "Default")
                        .foregroundStyle(.secondary)
                }.width(110)
            }
            .contextMenu(forSelectionType: UUID.self) { ids in
                Button("Edit") { editing = store.links.first { ids.contains($0.id) } }
                Button("Delete", role: .destructive) { store.delete(ids: ids) }
            } primaryAction: { ids in
                editing = store.links.first { ids.contains($0.id) }
            }

            HStack {
                Button { editing = Quicklink(name: "", link: "") } label: { Image(systemName: "plus") }
                Button { store.delete(ids: selection); selection = [] } label: { Image(systemName: "minus") }
                    .disabled(selection.isEmpty)
                Text("\(store.links.count) quicklinks").foregroundStyle(.secondary).font(.caption)
                Spacer()
                Button("Import from Raycast…", action: onImport)
                Button("Show JSON File") { NSWorkspace.shared.activateFileViewerSelecting([QuicklinkStore.fileURL]) }
            }
        }
        .padding()
        .frame(minWidth: 720, minHeight: 420)
        .sheet(item: $editing) { ql in
            QuicklinkEditor(link: ql) { store.upsert($0) }
        }
    }
}

struct QuicklinkEditor: View {
    @State var link: Quicklink
    var onSave: (Quicklink) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Form {
                TextField("Name", text: $link.name)
                TextField("Link", text: $link.link)
                TextField("Keyword", text: Binding(get: { link.keyword ?? "" },
                                                   set: { link.keyword = $0.isEmpty ? nil : $0 }))
                HStack {
                    TextField("Open With", text: Binding(get: { link.openWith ?? "" },
                                                         set: { link.openWith = $0.isEmpty ? nil : $0 }),
                              prompt: Text("Default app"))
                    Button("Choose…") {
                        let p = NSOpenPanel()
                        p.allowedContentTypes = [.application]
                        p.directoryURL = URL(fileURLWithPath: "/Applications")
                        if p.runModal() == .OK, let url = p.url {
                            link.openWith = Bundle(url: url)?.bundleIdentifier ?? url.path
                        }
                    }
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
}
