import FlickCore
import Foundation

final class QuicklinkStore: ObservableObject {
    @Published private(set) var links: [Quicklink] = []
    @Published private(set) var loadError: String?
    private let file = JSONFile<[Quicklink]>(url: AppSupport.quicklinksFile)
    private var loadedVersion: Date?

    static let starter = Quicklink(name: "Google Search", link: "https://www.google.com/search?q={argument}", keyword: "g")

    init() {
        if !file.exists {
            links = [Self.starter]
            save()
        }
        reloadIfChanged()
    }

    func reloadIfChanged() {
        let version = file.modificationDate
        guard version != loadedVersion else { return }
        loadedVersion = version
        do {
            links = try file.load()
            loadError = nil
        } catch {
            loadError = "quicklinks.json could not be read: \(error.localizedDescription)"
        }
    }

    func upsert(_ link: Quicklink) {
        if let i = links.firstIndex(where: { $0.id == link.id }) { links[i] = link } else { links.append(link) }
        save()
    }

    func delete(ids: Set<UUID>) {
        links.removeAll { ids.contains($0.id) }
        save()
    }

    func merge(_ incoming: [Quicklink]) -> Int {
        let new = incoming.filter { link in !links.contains { $0.isDuplicate(of: link) } }
        links += new
        save()
        return new.count
    }

    private func save() {
        file.save(links)
        loadedVersion = file.modificationDate
        loadError = nil
    }
}
