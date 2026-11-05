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
    private let store: QuicklinkStore
    private let usage: UsageStore
    private let runner: ResultRunner
    private var apps = AppIndex.scan()

    init(store: QuicklinkStore, usage: UsageStore, runner: ResultRunner) {
        self.store = store
        self.usage = usage
        self.runner = runner
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
        store.reloadIfChanged()
        argumentTarget = nil
        argument = ""
        enter(mode)
        rescanApps()
    }

    func enter(_ mode: Mode) {
        self.mode = mode
        query = ""
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
        if argumentTarget != nil { exitArgument() } else if let ql = argumentLink { enterArgument(ql) }
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
            refresh()
        }
    }

    private var searchResults: SearchResults {
        SearchResults(links: store.links, apps: apps, usage: usage.counts, commands: runner.commands.available)
    }

    private func refresh() {
        results = currentResults()
        selected = 0
    }

    private func currentResults() -> [ResultItem] {
        switch mode {
        case .root:
            let error = store.loadError.map { [ResultItem.message($0)] } ?? []
            return error + searchResults.results(for: query)
        case .emoji:
            return EmojiCatalog.results(for: query, usage: usage.counts)
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
