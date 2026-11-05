import FlickCore
import Foundation

final class ClipboardStore {
    private let file = JSONFile<[ClipEntry]>(url: AppSupport.clipboardFile)
    private(set) var entries: [ClipEntry]

    init() {
        entries = (try? file.load()) ?? []
    }

    func record(_ entry: ClipEntry) {
        entries = ClipHistory.adding(entry, to: entries)
        file.save(entries)
    }

    func delete(_ id: UUID) {
        entries.removeAll { $0.id == id }
        file.save(entries)
    }
}
