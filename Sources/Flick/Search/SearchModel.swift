import FlickCore
import Foundation

enum Field: Hashable { case query, argument }

final class SearchModel: ObservableObject {
    @Published var query = "" { didSet { if query != oldValue { queryChanged() } } }
    @Published var selected = 0
    @Published var argument = ""
    @Published private(set) var results: [ResultItem] = []
    @Published private(set) var argumentTarget: Quicklink?
    @Published private(set) var focus: Field = .query
    @Published private(set) var focusRequest = 0

    var onDone: () -> Void = {}
    private let store: QuicklinkStore
    private let usage: UsageStore
    private var apps = AppIndex.scan()

    init(store: QuicklinkStore, usage: UsageStore) {
        self.store = store
        self.usage = usage
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

    func prepareForShow() {
        store.reloadIfChanged()
        argumentTarget = nil
        argument = ""
        query = ""
        refresh()
        requestFocus(.query)
        rescanApps()
    }

    func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        if argumentTarget != nil { exitArgument() }
        selected = (selected + delta + results.count) % results.count
    }

    func tab() {
        if argumentTarget != nil { exitArgument() } else if let ql = argumentLink { enterArgument(ql) }
    }

    func escape() -> Bool {
        if argumentTarget != nil { exitArgument(); return true }
        if !query.isEmpty { query = ""; return true }
        return false
    }

    func deleteInEmptyArgument() -> Bool {
        guard argumentTarget != nil, argument.isEmpty else { return false }
        exitArgument()
        return true
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

    func activate(_ index: Int? = nil) {
        if index == nil, let ql = argumentTarget {
            activateArgument(of: ql)
            return
        }
        if argumentTarget != nil { exitArgument() }
        let i = index ?? selected
        guard results.indices.contains(i) else { return }
        selected = i
        run(results[i].kind)
    }

    private func activateArgument(of ql: Quicklink) {
        let text = argument.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        run(.quicklink(ql, argument: text))
    }

    private func run(_ kind: ResultKind) {
        if case .quicklink(let ql, nil) = kind, ql.takesArgument {
            enterArgument(ql)
            return
        }
        Launcher.open(kind)
        if let key = kind.usageKey { usage.record(key) }
        onDone()
    }

    private func queryChanged() {
        if argumentTarget == nil, query.hasSuffix(" "), let ql = searchResults.linkTriggered(by: String(query.dropLast())) {
            query = String(query.dropLast())
            refresh()
            enterArgument(ql)
        } else {
            refresh()
        }
    }

    private var searchResults: SearchResults {
        SearchResults(links: store.links, apps: apps, usage: usage.counts)
    }

    private func refresh() {
        let error = store.loadError.map { [ResultItem.message($0)] } ?? []
        results = error + searchResults.results(for: query)
        selected = 0
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
