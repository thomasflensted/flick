final class Library {
    let quicklinks = QuicklinkStore.quicklinks()
    let snippets = SnippetStore.snippets()

    func reloadIfChanged() {
        quicklinks.reloadIfChanged()
        snippets.reloadIfChanged()
    }
}
