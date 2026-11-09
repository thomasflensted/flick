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
    private let suggesters: [Quicklink: Suggesting] = [.googleSearch: Suggester(), .googleMaps: PlaceSuggester()]
    private let sources: [Mode: ModeSource]
    private var apps = AppIndex.scan()

    init(library: Library, usage: UsageStore, runner: ResultRunner, chat: ChatSession,
         rates: CurrencyRatesStore, translator: Translator) {
        self.library = library
        self.usage = usage
        self.runner = runner
        self.chat = chat
        self.rates = rates
        self.translator = translator
        sources = [
            .emoji: EmojiSource(usage: usage),
            .snippets: SnippetsSource(snippets: library.snippets, usage: usage),
            .clipboard: ClipboardSource(clipboard: library.clipboard),
            .models: ModelsSource(settings: chat.settings),
            .translate: TranslateSource(translator: translator),
            .servers: ServersSource(),
            .drives: DrivesSource(),
            .pullRequests: PullRequestsSource(),
            .timeZones: TimeZonesSource(),
            .weather: WeatherSource(),
        ]
        rates.onUpdate = { [weak self] in if self?.mode == .root { self?.refresh() } }
        for (mode, source) in sources {
            source.onUpdate = { [weak self] in if self?.mode == mode { self?.refreshKeepingSelection() } }
        }
        for (ql, suggester) in suggesters {
            suggester.onUpdate = { [weak self] in if self?.argumentTarget == ql { self?.refreshKeepingSelection() } }
        }
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
        if mode == .chat { chat.clearIfIdle(now: Date()) }
        query = mode == .chat ? chat.draft : ""
        sources[mode]?.enter()
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
        if !query.isEmpty, mode != .chat { query = ""; return true }
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
        suggester?.clear()
        argumentTarget = nil
        argument = ""
        if wasShowingSuggestions { refresh() }
        requestFocus(.query)
    }

    private var suggester: Suggesting? {
        argumentTarget.flatMap { suggesters[$0] }
    }

    private var showsSuggestions: Bool {
        suggester != nil
    }

    private var selectedIsSuggestion: Bool {
        showsSuggestions && selected > 0
    }

    private func argumentChanged() {
        guard let suggester else { return }
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

    var isLoading: Bool {
        sources[mode]?.isLoading ?? false
    }

    func removeSelected() {
        guard results.indices.contains(selected) else { return }
        sources[mode]?.remove(results[selected].kind)
    }

    func translateAgain() {
        translator.translate(query)
        refresh()
        requestFocus(.query)
    }

    func perform(_ action: ModeShortcut.Action) {
        switch action {
        case .swapLanguages: swapTranslateLanguages()
        case .newChat: newChat()
        case .switchModel: enter(.models)
        }
    }

    private func swapTranslateLanguages() {
        translator.swap()
        translateAgain()
    }

    private func newChat() {
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
            if mode == .chat { chat.draft = query }
            sources[mode]?.queryChanged(query)
            refresh()
        }
    }

    private var searchResults: SearchResults {
        SearchResults(links: Quicklink.withBuiltIns(library.quicklinks.items), apps: apps, usage: usage.counts, commands: runner.commands.available,
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
        guard mode == .root else { return sources[mode]?.results(for: query) ?? [] }
        if let suggester, let argumentTarget {
            return Suggestions.results(suggester.suggestions, for: argumentTarget)
        }
        let error = library.quicklinks.loadError.map { [ResultItem.quicklinksError($0)] } ?? []
        return error + searchResults.results(for: query)
    }

    private func requestFocus(_ field: Field) {
        focus = field
        focusRequest += 1
    }

    private func rescanApps() {
        Background.load(AppIndex.scan) { [weak self] in
            self?.apps = $0
            self?.refresh()
        }
    }
}
