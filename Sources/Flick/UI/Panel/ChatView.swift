import FlickCore
import SwiftUI

struct ChatView: View {
    @ObservedObject var chat: ChatSession
    @ObservedObject var settings: AISettings

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if chat.messages.isEmpty { emptyState }
                    ForEach(chat.messages) { message in
                        MessageBubble(message: message, thinking: chat.isAnswering && message.id == chat.messages.last?.id)
                    }
                    if let error = chat.error {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12)).foregroundStyle(.orange)
                    }
                    Color.clear.frame(height: 1).id(Self.bottom)
                }
                .padding(16)
            }
            .onChange(of: chat.messages.last?.content) { _, _ in scrollToBottom(proxy) }
            .onChange(of: chat.messages.last?.images.count) { _, _ in scrollToBottom(proxy) }
            .onAppear { scrollToBottom(proxy) }
        }
        .onAppear { settings.loadModels() }
    }

    private static let bottom = "bottom"

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        proxy.scrollTo(Self.bottom, anchor: .bottom)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles").font(.system(size: 28)).foregroundStyle(.purple)
            Text(settings.hasKey ? "Ask anything" : "Add your OpenRouter key to start")
                .font(.system(size: 15, weight: .semibold))
            Text(settings.hasKey ? "Answers come from \(settings.modelName)." : "Press ⌘, and open the AI tab.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 90)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let thinking: Bool

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 80) }
            content
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 12).fill(background))
                .textSelection(.enabled)
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder private var content: some View {
        if thinking && message.isEmpty {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Thinking…").foregroundStyle(.secondary)
            }
            .font(.system(size: 13))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if !message.content.isEmpty { Text(Markdown.render(message.content)).font(.system(size: 13)) }
                ForEach(message.images.indices, id: \.self) { GeneratedImage(data: message.images[$0]) }
            }
        }
    }

    private var background: Color {
        message.role == .user ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06)
    }
}

enum Markdown {
    static func render(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}
