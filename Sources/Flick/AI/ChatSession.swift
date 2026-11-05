import FlickCore
import Foundation

final class ChatSession: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isAnswering = false
    @Published private(set) var error: String?

    let settings: AISettings
    private var task: Task<Void, Never>?

    init(settings: AISettings) {
        self.settings = settings
    }

    func send(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isAnswering else { return }
        guard let key = settings.key else { error = "Add your OpenRouter key in Settings (⌘,) to start chatting."; return }
        guard let model = settings.modelID else { error = "Pick a model in Settings (⌘,) to start chatting."; return }
        error = nil
        messages.append(ChatMessage(id: messages.count, role: .user, content: text))
        let history = messages
        messages.append(ChatMessage(id: messages.count, role: .assistant, content: ""))
        isAnswering = true
        task = Task { @MainActor in await answer(key: key, model: model, history: history) }
    }

    func newChat() {
        task?.cancel()
        messages = []
        error = nil
        isAnswering = false
    }

    @MainActor
    private func answer(key: String, model: String, history: [ChatMessage]) async {
        do {
            for try await text in OpenRouterClient.stream(key: key, model: model, messages: history) {
                if Task.isCancelled { return }
                appendToAnswer(text)
            }
        } catch {
            if Task.isCancelled { return }
            self.error = error.localizedDescription
            if messages.last?.content.isEmpty == true { messages.removeLast() }
        }
        isAnswering = false
    }

    private func appendToAnswer(_ text: String) {
        guard let last = messages.indices.last, messages[last].role == .assistant else { return }
        messages[last].content += text
    }
}
