import AppKit

struct Quicklink: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var link: String
    /// App bundle id (e.g. "com.google.Chrome") or path to a .app. nil = system default.
    var openWith: String?
    /// Optional short alias typed to trigger the link, e.g. "gh".
    var keyword: String?

    init(name: String, link: String, openWith: String? = nil, keyword: String? = nil) {
        self.name = name
        self.link = link
        self.openWith = openWith
        self.keyword = keyword
    }

    // Lenient decoding so hand/agent-written JSON only needs name + link.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        link = try c.decode(String.self, forKey: .link)
        openWith = try c.decodeIfPresent(String.self, forKey: .openWith).flatMap { $0.isEmpty ? nil : $0 }
        keyword = try c.decodeIfPresent(String.self, forKey: .keyword).flatMap { $0.isEmpty ? nil : $0 }
    }

    // MARK: Placeholders ({argument}, {argument name="x" default="y"}, {query}, {clipboard})

    private static let placeholder = try! NSRegularExpression(
        pattern: #"\{\s*(argument|query|clipboard|selection)((?:\s+[a-zA-Z]+\s*=\s*"[^"]*")*)\s*(\|[^}]*)?\}"#)
    private static let attr = try! NSRegularExpression(pattern: #"([a-zA-Z]+)\s*=\s*"([^"]*)""#)

    var needsArgument: Bool {
        let ns = link as NSString
        return Self.placeholder.matches(in: link, range: NSRange(location: 0, length: ns.length)).contains {
            let kind = ns.substring(with: $0.range(at: 1))
            return kind == "argument" || kind == "query"
        }
    }

    /// Label for the inline argument field: the first {argument name="…"} or "Query".
    var argumentPlaceholder: String {
        let ns = link as NSString
        for m in Self.placeholder.matches(in: link, range: NSRange(location: 0, length: ns.length))
        where m.range(at: 2).location != NSNotFound {
            let attrs = ns.substring(with: m.range(at: 2))
            let ans = attrs as NSString
            for a in Self.attr.matches(in: attrs, range: NSRange(location: 0, length: ans.length))
            where ans.substring(with: a.range(at: 1)) == "name" {
                return ans.substring(with: a.range(at: 2))
            }
        }
        return "Query"
    }

    func resolved(argument: String) -> String {
        let ns = link as NSString
        let isURL = link.range(of: #"^[a-zA-Z][a-zA-Z0-9+.-]*:"#, options: .regularExpression) != nil
            && !link.hasPrefix("file:")
        var out = ""
        var last = 0
        for m in Self.placeholder.matches(in: link, range: NSRange(location: 0, length: ns.length)) {
            out += ns.substring(with: NSRange(location: last, length: m.range.location - last))
            last = m.range.location + m.range.length
            let kind = ns.substring(with: m.range(at: 1))
            let attrs = m.range(at: 2).location == NSNotFound ? "" : ns.substring(with: m.range(at: 2))
            let modifiers = m.range(at: 3).location == NSNotFound ? "" : ns.substring(with: m.range(at: 3))
            var defaultValue = ""
            let ans = attrs as NSString
            for a in Self.attr.matches(in: attrs, range: NSRange(location: 0, length: ans.length))
            where ans.substring(with: a.range(at: 1)) == "default" {
                defaultValue = ans.substring(with: a.range(at: 2))
            }
            var value: String
            switch kind {
            case "clipboard", "selection": value = NSPasteboard.general.string(forType: .string) ?? ""
            default: value = argument.isEmpty ? defaultValue : argument
            }
            if isURL && !modifiers.contains("raw") {
                var allowed = CharacterSet.urlQueryAllowed
                allowed.remove(charactersIn: "&+=?#")
                value = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            }
            out += value
        }
        out += ns.substring(from: last)
        return out
    }
}

/// Quicklinks live in a plain JSON array at
/// ~/Library/Application Support/Flick/quicklinks.json and are reloaded
/// whenever the file changes, so they can be edited by hand or by an agent.
final class QuicklinkStore: ObservableObject {
    static let dir: URL = {
        let d = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Flick", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()
    static let fileURL = dir.appendingPathComponent("quicklinks.json")

    @Published private(set) var links: [Quicklink] = []
    @Published private(set) var loadError: String?
    private var lastModified: Date?

    init() {
        if !FileManager.default.fileExists(atPath: Self.fileURL.path) {
            links = [Quicklink(name: "Google Search", link: "https://www.google.com/search?q={argument}", keyword: "g")]
            save()
        }
        reloadIfChanged()
    }

    func reloadIfChanged() {
        let mod = (try? FileManager.default.attributesOfItem(atPath: Self.fileURL.path))?[.modificationDate] as? Date
        guard mod != lastModified else { return }
        lastModified = mod
        do {
            let data = try Data(contentsOf: Self.fileURL)
            links = try JSONDecoder().decode([Quicklink].self, from: data)
            loadError = nil
        } catch {
            loadError = "quicklinks.json could not be read: \(error.localizedDescription)"
        }
    }

    func save() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        guard let data = try? enc.encode(links) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
        lastModified = (try? FileManager.default.attributesOfItem(atPath: Self.fileURL.path))?[.modificationDate] as? Date
        loadError = nil
    }

    func upsert(_ link: Quicklink) {
        if let i = links.firstIndex(where: { $0.id == link.id }) { links[i] = link } else { links.append(link) }
        save()
    }

    func delete(ids: Set<UUID>) {
        links.removeAll { ids.contains($0.id) }
        save()
    }

    /// Adds links that aren't already present (same name + link). Returns count added.
    @discardableResult
    func merge(_ incoming: [Quicklink]) -> Int {
        var added = 0
        for l in incoming where !links.contains(where: { $0.name == l.name && $0.link == l.link }) {
            links.append(l)
            added += 1
        }
        save()
        return added
    }
}

enum Opener {
    static func appURL(for openWith: String?) -> URL? {
        guard let o = openWith, !o.isEmpty else { return nil }
        if o.hasPrefix("/") || o.hasPrefix("~") {
            return URL(fileURLWithPath: (o as NSString).expandingTildeInPath)
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: o)
    }

    static func url(from string: String) -> URL? {
        let s = string.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("/") || s.hasPrefix("~") {
            return URL(fileURLWithPath: (s as NSString).expandingTildeInPath)
        }
        if s.range(of: #"^[a-zA-Z][a-zA-Z0-9+.-]*:"#, options: .regularExpression) != nil {
            return URL(string: s) ?? URL(string: s.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? s)
        }
        return URL(string: "https://" + s)
    }

    static func open(_ url: URL, with app: URL? = nil) {
        if let app {
            NSWorkspace.shared.open([url], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
    }
}
