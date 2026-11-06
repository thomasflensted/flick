import FlickCore
import Foundation

enum Field: Hashable { case query, argument }

final class SearchModel: ObservableObject {
    @Published var query = "" { didSet { if query != oldValue { queryChanged() } } }
    @Published var selected = 0
    @Published var argument = ""
    @Published private(set) var results: [ResultItem] = []
    @Published private(set) var argumentTarget: Quicklink?
    @Published private(set) var mode: Mode = .root
    @Published private(set) var focus: Field = .query
    @Published private(set) var focusRequest = 0

    var onDone: () -> Void = {}
    private let library: Library
    private let usage: UsageStore
    private let runner: ResultRunner
    let chat: ChatSession
    private let rates: CurrencyRatesStore
    let translator: Translator
    private var apps = AppIndex.scan()

    init(library: Library, usage: UsageStore, runner: ResultRunner, chat: ChatSession,
         rates: CurrencyRatesStore, translator: Translator) {
        self.library = library
        self.usage = usage
        self.runner = runner
        self.chat = chat
        self.rates = rates
        self.translator = translator
        rates.onUpdate = { [weak self] in if self?.mode == .root { self?.refresh() } }
        translator.onUpdate = { [weak self] in if self?.mode == .translate { self?.refresh() } }
    }

    var argumentLink: Quicklink? {
        if let argumentTarget { return argumentTarget }
        guard results.indices.contains(selected),
              case .quicklink(let ql, nil) = results[selected].kind, ql.takesArgument else { return nil }
        return ql
    }

    var inlineArgumentLink: Quicklink? {
        guard !query.isEmpty || argumentTarget != nil else { return nil }
        return argumentLink
    }

    func liveSubtitle(for item: ResultItem) -> String? {
        guard let target = argumentTarget, item.id == UsageKey.quicklink(target), !argument.isEmpty else { return nil }
        return target.resolved(argument: argument)
    }

    func prepareForShow(in mode: Mode) {
        library.reloadIfChanged()
        argumentTarget = nil
        argument = ""
        enter(mode)
        rates.refreshIfStale()
        rescanApps()
    }

    func enter(_ mode: Mode) {
        self.mode = mode
        query = ""
        if mode == .translate { translator.translate("") }
        if mode == .chat { chat.clearIfIdle(now: Date()) }
        refresh()
        requestFocus(.query)
    }

    var selectedTitle: String? {
        results.indices.contains(selected) ? results[selected].title : nil
    }

    var movesInGrid: Bool { mode.gridColumns != nil }

    func move(_ direction: Direction) {
        guard !results.isEmpty else { return }
        if argumentTarget != nil { exitArgument() }
        selected = Selection.next(from: selected, direction, count: results.count, columns: mode.gridColumns)
    }

    func tab() {
        if argumentTarget != nil { exitArgument(); return }
        if let ql = inlineArgumentLink { enterArgument(ql); return }
        if mode == .root { askAI(query) }
    }

    var tabHint: String {
        if argumentTarget != nil { return "Back to search" }
        return inlineArgumentLink == nil ? "Ask AI" : "Add query"
    }

    private func askAI(_ question: String) {
        let question = question.trimmingCharacters(in: .whitespaces)
        enter(.chat)
        if !question.isEmpty { chat.send(question) }
    }

    func escape() -> Bool {
        if argumentTarget != nil { exitArgument(); return true }
        if !query.isEmpty { query = ""; return true }
        if mode != .root { enter(.root); return true }
        return false
    }

    func deleteBackwardWhenEmpty() -> Bool {
        if argumentTarget != nil, argument.isEmpty { exitArgument(); return true }
        if argumentTarget == nil, mode != .root, query.isEmpty { enter(.root); return true }
        return false
    }

    func enterArgument(_ ql: Quicklink) {
        if query.isEmpty { query = ql.trigger }
        argumentTarget = ql
        argument = ""
        requestFocus(.argument)
    }

    func exitArgument() {
        argumentTarget = nil
        argument = ""
        requestFocus(.query)
    }

    var selectedProducesText: Bool {
        argumentTarget == nil && results.indices.contains(selected) && results[selected].kind.producesText
    }

    func activate(_ index: Int? = nil, delivery: Delivery = .paste) {
        if mode == .chat {
            sendChatMessage()
            return
        }
        if index == nil, let ql = argumentTarget {
            activateArgument(of: ql)
            return
        }
        if argumentTarget != nil { exitArgument() }
        let i = index ?? selected
        guard results.indices.contains(i) else { return }
        selected = i
        run(results[i].kind, delivery: delivery)
    }

    func deleteSelectedClip() {
        guard results.indices.contains(selected), case .clip(let entry) = results[selected].kind else { return }
        library.clipboard.delete(entry.id)
        let keep = selected
        refresh()
        selected = min(keep, max(results.count - 1, 0))
    }

    func translateAgain() {
        translator.translate(query)
        refresh()
        requestFocus(.query)
    }

    func swapTranslateLanguages() {
        translator.swap()
        translateAgain()
    }

    func newChat() {
        chat.newChat()
        requestFocus(.query)
    }

    private func sendChatMessage() {
        chat.send(query)
        query = ""
    }

    private func activateArgument(of ql: Quicklink) {
        let text = argument.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        run(.quicklink(ql, argument: text))
    }

    private func run(_ kind: ResultKind, delivery: Delivery = .paste) {
        switch runner.run(kind, delivery: delivery) {
        case .askArgument(let ql):
            enterArgument(ql)
        case .done:
            recordUsage(of: kind)
            onDone()
        case .enter(let mode):
            recordUsage(of: kind)
            enter(mode)
        case .ask(let question):
            askAI(question)
        case .stay:
            break
        }
    }

    private func recordUsage(of kind: ResultKind) {
        if let key = kind.usageKey { usage.record(key) }
    }

    private func queryChanged() {
        if mode == .root, argumentTarget == nil, query.hasSuffix(" "), let ql = searchResults.linkTriggered(by: String(query.dropLast())) {
            query = String(query.dropLast())
            refresh()
            enterArgument(ql)
        } else {
            if mode == .translate { translator.translate(query) }
            refresh()
        }
    }

    private var searchResults: SearchResults {
        SearchResults(links: library.quicklinks.items, apps: apps, usage: usage.counts, commands: runner.commands.available,
                      rates: rates.rates)
    }

    private func refresh() {
        results = currentResults()
        selected = 0
    }

    private func currentResults() -> [ResultItem] {
        switch mode {
        case .root:
            let error = library.quicklinks.loadError.map { [ResultItem.message($0)] } ?? []
            return error + searchResults.results(for: query)
        case .emoji:
            return EmojiCatalog.results(for: query, usage: usage.counts)
        case .snippets:
            return SnippetSearch.results(for: query, snippets: library.snippets.items, usage: usage.counts)
        case .clipboard:
            return ClipHistory.results(for: query, in: library.clipboard.entries, now: Date())
        case .translate:
            return GoogleTranslate.results(for: translator.state, text: query, pair: translator.pair,
                                           languages: translator.languages, locale: .current)
        case .chat:
            return []
        }
    }

    private func requestFocus(_ field: Field) {
        focus = field
        focusRequest += 1
    }

    private func rescanApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            let scanned = AppIndex.scan()
            DispatchQueue.main.async {
                self.apps = scanned
                self.refresh()
            }
        }
    }
}
