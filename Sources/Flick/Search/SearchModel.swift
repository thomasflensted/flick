import FlickCore
import Foundation

enum Field: Hashable { case query, argument }

final class SearchModel: ObservableObject {
    @Published var query = "" { didSet { if query != oldValue { queryChanged() } } }
    @Published var selected = 0
    @Published var argument = "" { didSet { if argument != oldValue { argumentChanged() } } }
    @Published private(set) var results: [ResultItem] = []
    @Published private(set) var argumentTarget: Quicklink?
    @Published private(set) var mode: Mode = .root
    @Published private(set) var focus: Field = .query
    @Published private(set) var focusRequest = 0
    @Published private(set) var runningAppPaths: Set<String> = []

    var onDone: () -> Void = {}
    private let library: Library
    private let usage: UsageStore
    private let runner: ResultRunner
    let chat: ChatSession
    private let rates: CurrencyRatesStore
    let translator: Translator
    private let suggester = Suggester()
    private var apps = AppIndex.scan()
    private var servers: [LiveServer] = []
    private var drives: [Drive] = []

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
        chat.settings.onModelsLoaded = { [weak self] in if self?.mode == .models { self?.refreshKeepingSelection() } }
        suggester.onUpdate = { [weak self] in if self?.showsSuggestions == true { self?.refreshKeepingSelection() } }
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
        runningAppPaths = RunningApps.paths()
        rescanApps()
    }

    func isRunning(_ kind: ResultKind) -> Bool {
        guard case .app(let app) = kind else { return false }
        return runningAppPaths.contains(app.path)
    }

    func enter(_ mode: Mode) {
        self.mode = mode
        query = ""
        if mode == .translate { translator.translate("") }
        if mode == .chat { chat.clearIfIdle(now: Date()) }
        if mode == .servers { rescanServers() }
        if mode == .drives { drives = MountedDrives.scan() }
        if mode == .models { chat.settings.loadModels() }
        refresh()
        requestFocus(.query)
    }

    var selectedTitle: String? {
        results.indices.contains(selected) ? results[selected].title : nil
    }

    var movesInGrid: Bool { mode.gridColumns != nil }

    func move(_ direction: Direction) {
        guard !results.isEmpty else { return }
        if argumentTarget != nil, !showsSuggestions { exitArgument() }
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
        if mode != .root { enter(mode.parent); return true }
        return false
    }

    func deleteBackwardWhenEmpty() -> Bool {
        if argumentTarget != nil, argument.isEmpty { exitArgument(); return true }
        if argumentTarget == nil, mode != .root, query.isEmpty { enter(mode.parent); return true }
        return false
    }

    func enterArgument(_ ql: Quicklink) {
        if query.isEmpty { query = ql.trigger }
        argumentTarget = ql
        argument = ""
        if showsSuggestions { refresh() }
        requestFocus(.argument)
    }

    func exitArgument() {
        let wasShowingSuggestions = showsSuggestions
        argumentTarget = nil
        argument = ""
        suggester.clear()
        if wasShowingSuggestions { refresh() }
        requestFocus(.query)
    }

    private var showsSuggestions: Bool {
        argumentTarget == .googleSearch
    }

    private var selectedIsSuggestion: Bool {
        showsSuggestions && selected > 0
    }

    private func argumentChanged() {
        guard showsSuggestions else { return }
        suggester.suggest(argument)
        refresh()
    }

    var selectedProducesText: Bool {
        argumentTarget == nil && results.indices.contains(selected) && results[selected].kind.producesText
    }

    func activate(_ index: Int? = nil, delivery: Delivery = .paste) {
        if mode == .chat {
            sendChatMessage()
            return
        }
        if index == nil, let ql = argumentTarget, !selectedIsSuggestion {
            activateArgument(of: ql)
            return
        }
        let i = index ?? selected
        guard results.indices.contains(i) else { return }
        let kind = results[i].kind
        if argumentTarget != nil { exitArgument() }
        selected = i
        run(kind, delivery: delivery)
    }

    func removeSelected() {
        guard results.indices.contains(selected) else { return }
        switch results[selected].kind {
        case .clip(let entry): library.clipboard.delete(entry.id)
        case .server(let server):
            ListeningServers.stop(server)
            servers.removeAll { $0 == server }
        case .drive(let drive):
            MountedDrives.eject(drive) { [weak self] in self?.driveEjected(drive) }
            return
        default: return
        }
        refreshKeepingSelection()
    }

    private func driveEjected(_ drive: Drive) {
        drives.removeAll { $0 == drive }
        if mode == .drives { refreshKeepingSelection() }
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
        case .useModel(let model):
            chat.settings.modelID = model.id
            enter(.chat)
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
        SearchResults(links: [.googleSearch] + library.quicklinks.items, apps: apps, usage: usage.counts, commands: runner.commands.available,
                      rates: rates.rates)
    }

    private func refresh() {
        results = currentResults()
        selected = 0
    }

    private func refreshKeepingSelection() {
        let keep = selected
        results = currentResults()
        selected = min(keep, max(results.count - 1, 0))
    }

    private func currentResults() -> [ResultItem] {
        switch mode {
        case .root:
            if showsSuggestions {
                return GoogleSuggest.results(suggestions: suggester.suggestions)
            }
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
        case .servers:
            return LiveServers.results(for: query, in: servers)
        case .drives:
            return Drives.results(for: query, in: drives)
        case .timeZones:
            return WorldClock.results(for: query, now: Date(), local: .current, locale: .current)
        case .chat:
            return []
        case .models:
            let settings = chat.settings
            return ModelCatalog.results(for: query, popular: settings.popularModels, all: settings.models, currentID: settings.modelID)
        }
    }

    private func requestFocus(_ field: Field) {
        focus = field
        focusRequest += 1
    }

    private func rescanServers() {
        DispatchQueue.global(qos: .userInitiated).async {
            let scanned = ListeningServers.scan()
            DispatchQueue.main.async {
                self.servers = scanned
                if self.mode == .servers { self.refresh() }
            }
        }
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
