import FlickCore
import Foundation

final class ListStore<Item: Listable>: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var loadError: String?
    private var file: JSONFile<[Item]>
    private var loadedVersion: Date?

    init(file url: URL, starter: [Item] = []) {
        file = JSONFile(url: url)
        if !file.exists {
            items = starter
            save()
        }
        reloadIfChanged()
    }

    var fileURL: URL { file.url }

    func reloadIfChanged() {
        let version = file.modificationDate
        guard version != loadedVersion else { return }
        loadedVersion = version
        do {
            items = try file.load()
            loadError = nil
        } catch {
            loadError = "\(file.url.lastPathComponent) could not be read: \(error.localizedDescription)"
        }
    }

    func upsert(_ item: Item) {
        items.upsert(item)
        save()
    }

    func replace(with items: [Item]) {
        self.items = items
        save()
    }

    func delete(ids: Set<UUID>) {
        items.removeAll { ids.contains($0.id) }
        save()
    }

    func merge(_ incoming: [Item]) -> Int {
        let new = incoming.filter { item in !items.contains { $0.isDuplicate(of: item) } }
        items += new
        save()
        return new.count
    }

    func relocate(to url: URL, targetIsLocal: Bool) {
        let carried = items
        file = JSONFile(url: url)
        loadedVersion = nil
        switch RelocationStrategy.moving(toExisting: file.exists, targetIsLocal: targetIsLocal) {
        case .overwrite:
            replace(with: carried)
        case .merge:
            reloadIfChanged()
            guard loadError == nil else { return }
            _ = merge(carried)
        }
    }

    private func save() {
        file.save(items)
        loadedVersion = file.modificationDate
        loadError = nil
    }
}

typealias QuicklinkStore = ListStore<Quicklink>
typealias SnippetStore = ListStore<Snippet>

extension ListStore where Item == Quicklink {
    static func quicklinks() -> QuicklinkStore {
        QuicklinkStore(file: AppSupport.quicklinksFile,
                       starter: [Quicklink(name: "Google Search", link: "https://www.google.com/search?q={argument}", keyword: "g")])
    }
}

extension ListStore where Item == Snippet {
    static func snippets() -> SnippetStore {
        SnippetStore(file: AppSupport.snippetsFile)
    }
}
