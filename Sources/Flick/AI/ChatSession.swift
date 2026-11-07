import FlickCore
import Foundation

final class ChatSession: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isAnswering = false
    @Published private(set) var error: String?

    let settings: AISettings
    private let library: Library
    private var task: Task<Void, Never>?
    private var lastActivity: Date?

    init(settings: AISettings, library: Library) {
        self.settings = settings
        self.library = library
    }

    func send(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isAnswering else { return }
        guard let key = settings.key, let model = settings.model else { error = settings.setupProblem; return }
        error = nil
        messages.append(ChatMessage(id: messages.count, role: .user, content: text))
        isAnswering = true
        lastActivity = Date()
        task = Task { @MainActor in await answer(key: key, model: model) }
    }

    func revert(messageID: Int, resultIndex: Int) {
        guard !isAnswering, messages.indices.contains(messageID) else { return }
        let result = messages[messageID].toolResults[resultIndex]
        guard let change = result.change, !result.isReverted else { return }
        library.reloadIfChanged()
        if let problem = libraryProblem { error = problem; return }
        var workspace = currentWorkspace
        workspace.revert(change)
        save(workspace)
        messages[messageID].toolResults[resultIndex].isReverted = true
    }

    func clearIfIdle(now: Date) {
        if !isAnswering, ChatExpiry.isExpired(lastActivity: lastActivity, now: now) { newChat() }
    }

    func newChat() {
        task?.cancel()
        messages = []
        error = nil
        isAnswering = false
    }

    @MainActor
    private func answer(key: String, model: AIModel) async {
        do {
            try await answerUsingTools(key: key, model: model)
        } catch {
            if Task.isCancelled { return }
            self.error = error.localizedDescription
            if messages.last?.isEmpty == true { messages.removeLast() }
        }
        if Task.isCancelled { return }
        isAnswering = false
        lastActivity = Date()
    }

    @MainActor
    private func answerUsingTools(key: String, model: AIModel) async throws {
        for _ in 0..<ChatPrompt.maxToolRounds {
            let history = messages
            messages.append(ChatMessage(id: messages.count, role: .assistant, content: ""))
            let calls = try await streamAnswer(key: key, model: model, history: history)
            if calls.isEmpty || Task.isCancelled { return }
            runTools(calls)
        }
        error = ChatPrompt.tooManyToolRounds
    }

    @MainActor
    private func streamAnswer(key: String, model: AIModel, history: [ChatMessage]) async throws -> [ToolCall] {
        var assembler = ToolCallAssembler()
        for try await event in OpenRouterClient.stream(key: key, model: model, messages: history) {
            if Task.isCancelled { return [] }
            switch event {
            case .answer(let part): updateAnswer { $0.append(part) }
            case .toolCall(let delta): assembler.add(delta)
            case .failed, .done: break
            }
        }
        return assembler.calls
    }

    private func runTools(_ calls: [ToolCall]) {
        library.reloadIfChanged()
        if let problem = libraryProblem {
            updateAnswer { $0.toolCalls = calls; $0.toolResults = calls.map { ToolResult(callID: $0.id, output: "Error: \(problem)") } }
            return
        }
        var workspace = currentWorkspace
        let results = calls.map { workspace.perform($0) }
        save(workspace)
        updateAnswer { $0.toolCalls = calls; $0.toolResults = results }
    }

    private var libraryProblem: String? {
        (library.quicklinks.loadError ?? library.snippets.loadError).map { "\($0) Fix the file before changing settings." }
    }

    private var currentWorkspace: SettingsWorkspace {
        SettingsWorkspace(quicklinks: library.quicklinks.items, snippets: library.snippets.items)
    }

    private func save(_ workspace: SettingsWorkspace) {
        if workspace.quicklinks != library.quicklinks.items { library.quicklinks.replace(with: workspace.quicklinks) }
        if workspace.snippets != library.snippets.items { library.snippets.replace(with: workspace.snippets) }
    }

    private func updateAnswer(_ update: (inout ChatMessage) -> Void) {
        guard let last = messages.indices.last, messages[last].role == .assistant else { return }
        update(&messages[last])
    }
}
