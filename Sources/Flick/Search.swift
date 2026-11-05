import AppKit
import Combine

struct AppEntry: Hashable {
    let name: String
    let path: String
}

enum AppIndex {
    static func scan() -> [AppEntry] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        let roots = ["/Applications", "/Applications/Utilities", "/System/Applications",
                     "/System/Applications/Utilities", "\(home)/Applications"]
        var seen = Set<String>()
        var out: [AppEntry] = []
        func add(_ path: String) {
            guard path.hasSuffix(".app"), seen.insert(path).inserted else { return }
            out.append(AppEntry(name: fm.displayName(atPath: path).replacingOccurrences(of: ".app", with: ""), path: path))
        }
        for root in roots {
            for item in (try? fm.contentsOfDirectory(atPath: root)) ?? [] {
                let path = "\(root)/\(item)"
                if item.hasSuffix(".app") { add(path); continue }
                var isDir: ObjCBool = false
                // One level deep for vendor folders like "Adobe Lightroom CC".
                if fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue, !item.hasPrefix(".") {
                    for sub in (try? fm.contentsOfDirectory(atPath: path)) ?? [] where sub.hasSuffix(".app") {
                        add("\(path)/\(sub)")
                    }
                }
            }
        }
        add("/System/Library/CoreServices/Finder.app")
        return out
    }
}

enum ResultKind {
    case quicklink(Quicklink, argument: String?)
    case app(AppEntry)
    case url(URL)
    case google(String)
    case message(String)
}

struct ResultItem: Identifiable {
    let id: String
    let kind: ResultKind
    let title: String
    let subtitle: String
}

func matchScore(_ query: String, _ target: String) -> Int? {
    let q = query.lowercased(), t = target.lowercased()
    if q.isEmpty { return 0 }
    if t == q { return 1000 }
    if t.hasPrefix(q) { return 800 }
    let words = t.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
    if words.contains(where: { $0.hasPrefix(q) }) { return 600 }
    if String(words.compactMap(\.first)).hasPrefix(q) { return 500 }
    if t.contains(q) { return 400 }
    var it = t.makeIterator()
    for c in q {
        var found = false
        while let x = it.next() { if x == c { found = true; break } }
        if !found { return nil }
    }
    return 200
}

enum Field: Hashable { case query, argument }

final class SearchModel: ObservableObject {
    @Published var query = "" {
        didSet {
            guard query != oldValue else { return }
            // "g " (a keyword/name + space) jumps straight into the argument field.
            if argumentTarget == nil, query.hasSuffix(" "), let ql = argumentLink(matching: String(query.dropLast())) {
                query = String(query.dropLast())
                update()
                enterArgument(ql)
                return
            }
            update()
        }
    }
    @Published private(set) var results: [ResultItem] = []
    @Published var selected = 0
    @Published var focusToken = 0
    @Published var focusField: Field = .query
    /// The quicklink whose inline argument field is active.
    @Published private(set) var argumentTarget: Quicklink?
    @Published var argument = ""

    /// The quicklink to show the inline argument field for (active target, or the selected row).
    var argumentLink: Quicklink? {
        if let argumentTarget { return argumentTarget }
        guard results.indices.contains(selected),
              case .quicklink(let ql, let arg) = results[selected].kind,
              ql.needsArgument, arg == nil else { return nil }
        return ql
    }

    private func argumentLink(matching text: String) -> Quicklink? {
        let key = text.lowercased()
        guard !key.isEmpty else { return nil }
        return store.links.first { ql in
            ql.needsArgument && [ql.keyword, ql.name].compactMap { $0?.lowercased() }.contains(key)
        }
    }

    func enterArgument(_ ql: Quicklink) {
        if query.isEmpty { query = ql.keyword ?? ql.name }
        argumentTarget = ql
        argument = ""
        focusField = .argument
        focusToken += 1
    }

    func exitArgument() {
        argumentTarget = nil
        argument = ""
        focusField = .query
        focusToken += 1
    }

    let store: QuicklinkStore
    var onDone: () -> Void = {}
    private var apps: [AppEntry] = []
    private var usage: [String: Int] = [:]
    private static let usageURL = QuicklinkStore.dir.appendingPathComponent("usage.json")

    init(store: QuicklinkStore) {
        self.store = store
        if let d = try? Data(contentsOf: Self.usageURL),
           let u = try? JSONDecoder().decode([String: Int].self, from: d) { usage = u }
        apps = AppIndex.scan()
    }

    func prepareForShow() {
        store.reloadIfChanged()
        argumentTarget = nil
        argument = ""
        focusField = .query
        query = ""
        update()
        focusToken += 1
        DispatchQueue.global(qos: .userInitiated).async {
            let a = AppIndex.scan()
            DispatchQueue.main.async { self.apps = a; self.update() }
        }
    }

    private func key(_ kind: ResultKind) -> String? {
        switch kind {
        case .quicklink(let q, _): return "ql:\(q.id)"
        case .app(let a): return "app:\(a.path)"
        default: return nil
        }
    }

    private func boost(_ k: String) -> Int { min((usage[k] ?? 0) * 15, 300) }

    private func item(ql: Quicklink, argument: String?) -> ResultItem {
        let sub: String
        if let argument, !argument.isEmpty { sub = ql.resolved(argument: argument) }
        else if ql.needsArgument { sub = "Press ⇥ to add a \(ql.argumentPlaceholder.lowercased())" }
        else { sub = ql.link }
        return ResultItem(id: "ql:\(ql.id)", kind: .quicklink(ql, argument: argument), title: ql.name, subtitle: sub)
    }

    func update() {
        let q = query.trimmingCharacters(in: .whitespaces)
        let lower = query.lowercased()
        var scored: [(Int, ResultItem)] = []

        if let err = store.loadError {
            scored.append((10_000, ResultItem(id: "err", kind: .message(err), title: "Quicklinks file has an error", subtitle: err)))
        }

        if q.isEmpty {
            // Most-used items as a starting list.
            let ranked = usage.sorted { $0.value > $1.value }.prefix(8)
            for (k, n) in ranked {
                if k.hasPrefix("ql:"), let ql = store.links.first(where: { "ql:\($0.id)" == k }) {
                    scored.append((n, item(ql: ql, argument: nil)))
                } else if k.hasPrefix("app:"), let a = apps.first(where: { "app:\($0.path)" == k }) {
                    scored.append((n, ResultItem(id: k, kind: .app(a), title: a.name, subtitle: "Application")))
                }
            }
            if scored.isEmpty {
                scored = store.links.prefix(8).map { (0, item(ql: $0, argument: nil)) }
            }
            publish(scored.sorted { $0.0 > $1.0 }.map(\.1))
            return
        }

        var argumentMode = Set<UUID>()
        for ql in store.links where ql.needsArgument {
            for k in [ql.keyword, ql.name].compactMap({ $0 }) where !k.isEmpty {
                let prefix = k.lowercased() + " "
                if lower.hasPrefix(prefix) {
                    argumentMode.insert(ql.id)
                    scored.append((5000 + k.count, item(ql: ql, argument: String(query.dropFirst(prefix.count)))))
                    break
                }
            }
        }

        for ql in store.links where !argumentMode.contains(ql.id) {
            var s = matchScore(q, ql.name)
            if let kw = ql.keyword {
                if kw.lowercased() == q.lowercased() { s = 1100 }
                else if let ks = matchScore(q, kw), ks >= 800 { s = max(s ?? 0, ks) }
            }
            if let s { scored.append((s + 50 + boost("ql:\(ql.id)"), item(ql: ql, argument: nil))) }
        }

        for a in apps {
            if let s = matchScore(q, a.name) {
                scored.append((s + boost("app:\(a.path)"), ResultItem(id: "app:\(a.path)", kind: .app(a), title: a.name, subtitle: "Application")))
            }
        }

        var list = scored.sorted { $0.0 > $1.0 }.prefix(30).map(\.1)
        if !q.contains(" "), q.contains("."), let url = Opener.url(from: q), url.host?.contains(".") == true || q.contains("://") {
            list.append(ResultItem(id: "url", kind: .url(url), title: "Open \(q)", subtitle: url.absoluteString))
        }
        list.append(ResultItem(id: "google", kind: .google(q), title: "Search Google for \u{201C}\(q)\u{201D}", subtitle: "google.com"))
        publish(list)
    }

    private func publish(_ list: [ResultItem]) {
        results = list
        selected = 0
    }

    func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        if argumentTarget != nil { exitArgument() }
        selected = (selected + delta + results.count) % results.count
    }

    /// Tab: toggle the inline argument field for the selected quicklink.
    func tab() {
        if argumentTarget != nil { exitArgument(); return }
        if let ql = argumentLink { enterArgument(ql) }
    }

    func activate(_ index: Int? = nil) {
        if index == nil, let ql = argumentTarget {
            let arg = argument.trimmingCharacters(in: .whitespaces)
            guard !arg.isEmpty else { return }
            run(ResultItem(id: "ql:\(ql.id)", kind: .quicklink(ql, argument: arg), title: ql.name, subtitle: ""))
            return
        }
        if argumentTarget != nil { exitArgument() }
        let i = index ?? selected
        guard results.indices.contains(i) else { return }
        if index != nil { selected = i }
        run(results[i])
    }

    private func run(_ r: ResultItem) {
        switch r.kind {
        case .quicklink(let ql, let arg):
            if ql.needsArgument && arg == nil { enterArgument(ql); return }
            guard let url = Opener.url(from: ql.resolved(argument: arg ?? "")) else { return }
            Opener.open(url, with: Opener.appURL(for: ql.openWith))
        case .app(let a):
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: a.path), configuration: NSWorkspace.OpenConfiguration())
        case .url(let url):
            Opener.open(url)
        case .google(let text):
            var allowed = CharacterSet.urlQueryAllowed
            allowed.remove(charactersIn: "&+=?#")
            let enc = text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
            if let url = URL(string: "https://www.google.com/search?q=\(enc)") { Opener.open(url) }
        case .message:
            NSWorkspace.shared.activateFileViewerSelecting([QuicklinkStore.fileURL])
        }
        if let k = key(r.kind) {
            usage[k, default: 0] += 1
            if let d = try? JSONEncoder().encode(usage) { try? d.write(to: Self.usageURL, options: .atomic) }
        }
        onDone()
    }
}
