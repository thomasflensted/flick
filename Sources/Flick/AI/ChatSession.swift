import FlickCore
import Foundation

final class ChatSession: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isAnswering = false
    @Published private(set) var error: String?

    let settings: AISettings
    private var task: Task<Void, Never>?
    private var lastActivity: Date?

    init(settings: AISettings) {
        self.settings = settings
    }

    func send(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isAnswering else { return }
        guard let key = settings.key else { error = "Add your OpenRouter key in Settings (⌘,) to start chatting."; return }
        guard let model = settings.model else { error = "Pick a model in Settings (⌘,) to start chatting."; return }
        error = nil
        messages.append(ChatMessage(id: messages.count, role: .user, content: text))
        let history = messages
        messages.append(ChatMessage(id: messages.count, role: .assistant, content: ""))
        isAnswering = true
        lastActivity = Date()
        task = Task { @MainActor in await answer(key: key, model: model, history: history) }
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
    private func answer(key: String, model: AIModel, history: [ChatMessage]) async {
        do {
            for try await event in OpenRouterClient.stream(key: key, model: model, messages: history) {
                if Task.isCancelled { return }
                appendToAnswer(event)
            }
        } catch {
            if Task.isCancelled { return }
            self.error = error.localizedDescription
            if messages.last?.isEmpty == true { messages.removeLast() }
        }
        isAnswering = false
        lastActivity = Date()
    }

    private func appendToAnswer(_ event: StreamEvent) {
        guard let last = messages.indices.last, messages[last].role == .assistant else { return }
        switch event {
        case .text(let text): messages[last].content += text
        case .image(let data): messages[last].images.append(data)
        case .failed, .done: break
        }
    }
}
