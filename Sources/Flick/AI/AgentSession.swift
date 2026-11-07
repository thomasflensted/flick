import FlickCore
import Foundation

struct AgentEntry: Identifiable {
    enum Kind {
        case user(String)
        case reply(String)
        case change(AgentChange)
        case note(String)
    }

    let id: Int
    let kind: Kind
}

final class AgentSession: ObservableObject {
    @Published private(set) var entries: [AgentEntry] = []
    @Published private(set) var isWorking = false
    @Published private(set) var error: String?
    @Published private(set) var undoSnapshot: AgentWorkspace?

    let settings: AISettings
    private let library: Library
    private var history = AgentSession.freshHistory
    private var task: Task<Void, Never>?
    private var lastActivity: Date?

    private static let freshHistory = [AgentMessage(role: .system, content: AgentPrompt.system)]

    init(settings: AISettings, library: Library) {
        self.settings = settings
        self.library = library
    }

    var canUndo: Bool { undoSnapshot != nil && !isWorking }

    func send(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isWorking else { return }
        guard let key = settings.key, let model = settings.model else { error = settings.setupProblem; return }
        library.reloadIfChanged()
        if let loadError = library.quicklinks.loadError ?? library.snippets.loadError {
            error = "\(loadError) Fix the file before using the agent."
            return
        }
        error = nil
        add(.user(text))
        history.append(.user(text))
        isWorking = true
        lastActivity = Date()
        task = Task { @MainActor in await run(key: key, model: model) }
    }

    func undo() {
        guard canUndo, let undoSnapshot else { return }
        save(undoSnapshot)
        self.undoSnapshot = nil
        add(.note("Undid the last changes."))
        history.append(.user(AgentPrompt.undoneNote))
    }

    func clearIfIdle(now: Date) {
        if !isWorking, ChatExpiry.isExpired(lastActivity: lastActivity, now: now) { newConversation() }
    }

    func newConversation() {
        task?.cancel()
        entries = []
        history = Self.freshHistory
        error = nil
        undoSnapshot = nil
        isWorking = false
    }

    @MainActor
    private func run(key: String, model: AIModel) async {
        let before = currentWorkspace
        var workspace = before
        do {
            try await converse(key: key, model: model, workspace: &workspace)
        } catch {
            if !Task.isCancelled { self.error = error.localizedDescription }
        }
        if Task.isCancelled { return }
        if workspace != before { undoSnapshot = before }
        isWorking = false
        lastActivity = Date()
    }

    @MainActor
    private func converse(key: String, model: AIModel, workspace: inout AgentWorkspace) async throws {
        for _ in 0..<AgentPrompt.maxRounds {
            let reply = try await AgentClient.send(key: key, model: model, messages: history)
            if Task.isCancelled { return }
            history.append(reply)
            if let text = reply.text { add(.reply(text)) }
            if reply.calls.isEmpty { return }
            for call in reply.calls {
                let outcome = workspace.perform(call)
                history.append(.tool(callID: call.id, output: outcome.output))
                if let change = outcome.change { add(.change(change)) }
            }
            save(workspace)
        }
        error = AgentPrompt.tooManyRounds
    }

    private var currentWorkspace: AgentWorkspace {
        AgentWorkspace(quicklinks: library.quicklinks.items, snippets: library.snippets.items)
    }

    private func save(_ workspace: AgentWorkspace) {
        if workspace.quicklinks != library.quicklinks.items { library.quicklinks.replace(with: workspace.quicklinks) }
        if workspace.snippets != library.snippets.items { library.snippets.replace(with: workspace.snippets) }
    }

    private func add(_ kind: AgentEntry.Kind) {
        entries.append(AgentEntry(id: entries.count, kind: kind))
    }
}
