import Foundation


public struct SearchResults {
    public let links: [Quicklink]
    public let apps: [AppEntry]
    public let usage: [String: Int]
    public let commands: [Command]
    public let rates: CurrencyRates?
    public let locale: Locale

    static let recentsLimit = 8
    static let resultLimit = 30
    static let quicklinkBonus = 50
    static let keywordScore = 1100
    static let argumentScore = 5000
    static let keepAwakeTriggers = ["keep awake", "awake", "caffeinate"]
    static let minimumTriggerPrefix = 3

    public init(links: [Quicklink], apps: [AppEntry], usage: [String: Int], commands: [Command] = [], rates: CurrencyRates? = nil, locale: Locale = .current) {
        self.links = links
        self.apps = apps
        self.usage = usage
        self.commands = commands
        self.rates = rates
        self.locale = locale
    }

    public func results(for query: String) -> [ResultItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return recents() }
        let candidates: [[Scored]] = [
            argumentMatches(query), timedKeepAwake(trimmed), quicklinkMatches(trimmed, excluding: query),
            appMatches(trimmed), commandMatches(trimmed), modeMatches(trimmed),
        ]
        let ranked = candidates.flatMap { $0 }
            .sorted { $0.score > $1.score }
            .prefix(Self.resultLimit)
            .map(\.item)
        return conversions(trimmed) + ranked + webResults(trimmed)
    }

    public func linkTriggered(by text: String) -> Quicklink? {
        links.first { $0.takesArgument && $0.isTriggered(by: text) }
    }

    static func usageBoost(_ count: Int) -> Int { min(count * 15, 300) }

    static func quicklinkScore(_ query: String, _ ql: Quicklink) -> Int? {
        if let keyword = ql.keyword, keyword.lowercased() == query.lowercased() { return keywordScore }
        let nameScore = MatchScore.score(query, against: ql.name)
        let keywordPrefixScore = ql.keyword.flatMap { MatchScore.score(query, against: $0) }.flatMap { $0 >= MatchScore.prefix ? $0 : nil }
        return [nameScore, keywordPrefixScore].compactMap { $0 }.max()
    }

    static func argument(in query: String, for ql: Quicklink) -> String? {
        guard ql.takesArgument else { return nil }
        for trigger in [ql.keyword, ql.name].compactMap({ $0 }) {
            let prefix = trigger.lowercased() + " "
            if query.lowercased().hasPrefix(prefix) { return String(query.dropFirst(prefix.count)) }
        }
        return nil
    }

    private typealias Scored = (score: Int, item: ResultItem)

    private func recents() -> [ResultItem] {
        let items = usage.sorted { $0.value > $1.value }.compactMap { item(forUsageKey: $0.key) }.prefix(Self.recentsLimit)
        return items.isEmpty ? links.prefix(Self.recentsLimit).map { .quicklink($0) } : Array(items)
    }

    private func item(forUsageKey key: String) -> ResultItem? {
        if let ql = links.first(where: { UsageKey.quicklink($0) == key }) { return .quicklink(ql) }
        if let app = apps.first(where: { UsageKey.app($0) == key }) { return .app(app) }
        if let command = commands.first(where: { UsageKey.command($0) == key }) { return .command(command) }
        if let mode = Mode.openable.first(where: { UsageKey.mode($0) == key }) { return .mode(mode) }
        return nil
    }

    private func argumentMatches(_ query: String) -> [Scored] {
        links.compactMap { ql in
            Self.argument(in: query, for: ql).map { (Self.argumentScore + query.count - $0.count, ResultItem.quicklink(ql, argument: $0)) }
        }
    }

    private func quicklinkMatches(_ query: String, excluding fullQuery: String) -> [Scored] {
        links.compactMap { ql in
            guard Self.argument(in: fullQuery, for: ql) == nil, let score = Self.quicklinkScore(query, ql) else { return nil }
            return (score + Self.quicklinkBonus + boost(UsageKey.quicklink(ql)), .quicklink(ql))
        }
    }

    private func appMatches(_ query: String) -> [Scored] {
        apps.compactMap { app in
            MatchScore.score(query, against: app.name).map { ($0 + boost(UsageKey.app(app)), .app(app)) }
        }
    }

    private func commandMatches(_ query: String) -> [Scored] {
        commands.compactMap { command in
            bestScore(query, [command.title] + command.aliases).map { ($0 + boost(UsageKey.command(command)), .command(command)) }
        }
    }

    private func modeMatches(_ query: String) -> [Scored] {
        Mode.openable.compactMap { mode in
            bestScore(query, [mode.commandTitle] + mode.aliases).map { ($0 + boost(UsageKey.mode(mode)), .mode(mode)) }
        }
    }

    private func timedKeepAwake(_ query: String) -> [Scored] {
        guard let minutes = Self.keepAwakeMinutes(in: query) else { return [] }
        return [(Self.argumentScore, .command(.keepAwakeFor(minutes: minutes)))]
    }

    static func keepAwakeMinutes(in query: String) -> Int? {
        guard let space = query.lastIndex(of: " ") else { return nil }
        let trigger = query[..<space].lowercased()
        guard trigger.count >= minimumTriggerPrefix, keepAwakeTriggers.contains(where: { $0.hasPrefix(trigger) }) else { return nil }
        return DurationText.minutes(from: String(query[query.index(after: space)...]))
    }

    private func conversions(_ query: String) -> [ResultItem] {
        guard let rates else { return [] }
        let local = locale.currency?.identifier ?? "USD"
        return CurrencyConverter.conversions(for: query, rates: rates, local: local).map { .conversion($0, locale: locale) }
    }

    private func webResults(_ query: String) -> [ResultItem] {
        let open = URLText.looksLikeWebAddress(query) ? URLText.url(from: query).map { ResultItem.url($0, typed: query) } : nil
        return [open, .google(query), .askAI(query)].compactMap { $0 }
    }

    private func bestScore(_ query: String, _ texts: [String]) -> Int? {
        texts.compactMap { MatchScore.score(query, against: $0) }.max()
    }

    private func boost(_ key: String) -> Int { Self.usageBoost(usage[key] ?? 0) }
}
