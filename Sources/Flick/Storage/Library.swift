import Foundation

final class Library {
    let quicklinks = QuicklinkStore.quicklinks()
    let snippets = SnippetStore.snippets()
    let clipboard = ClipboardStore()

    func reloadIfChanged() {
        quicklinks.reloadIfChanged()
        snippets.reloadIfChanged()
    }

    func useSyncFolder(_ path: String?) {
        AppSupport.syncFolder = path
        try? FileManager.default.createDirectory(at: AppSupport.syncedDirectory, withIntermediateDirectories: true)
        quicklinks.relocate(to: AppSupport.quicklinksFile, targetIsLocal: path == nil)
        snippets.relocate(to: AppSupport.snippetsFile, targetIsLocal: path == nil)
    }
}
