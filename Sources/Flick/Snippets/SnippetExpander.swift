import AppKit
import FlickCore

final class SnippetExpander {
    private let store: SnippetStore
    private var typed = TypedText()
    private lazy var monitor = KeyboardMonitor { [weak self] event in self?.handle(event) }

    init(store: SnippetStore) {
        self.store = store
    }

    func start() {
        monitor.start()
    }

    private func handle(_ event: TypingEvent) {
        switch event {
        case .typed(let characters):
            typed.type(characters)
            expandIfMatched()
        case .deleteBackward:
            typed.deleteBackward()
        case .interrupted:
            typed.reset()
        }
    }

    private func expandIfMatched() {
        guard NSApp.keyWindow == nil else { return }
        store.reloadIfChanged()
        guard let snippet = SnippetExpansion.match(in: typed.text, snippets: store.items), let keyword = snippet.keyword else { return }
        typed.reset()
        Paster.replaceTyped(characters: keyword.count, with: snippet.expanded())
    }
}
