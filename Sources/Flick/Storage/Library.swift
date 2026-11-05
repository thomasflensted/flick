final class Library {
    let quicklinks = QuicklinkStore.quicklinks()
    let snippets = SnippetStore.snippets()
    let clipboard = ClipboardStore()

    func reloadIfChanged() {
        quicklinks.reloadIfChanged()
        snippets.reloadIfChanged()
    }
}
