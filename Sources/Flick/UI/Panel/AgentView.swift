import FlickCore
import SwiftUI

struct AgentView: View {
    @ObservedObject var agent: AgentSession
    @ObservedObject var settings: AISettings

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if agent.entries.isEmpty { emptyState }
                    ForEach(agent.entries) { entry in
                        row(entry.kind)
                    }
                    if agent.isWorking { MessageBubble(message: ChatMessage(id: 0, role: .assistant, content: ""), thinking: true) }
                    if let error = agent.error { ErrorLabel(text: error) }
                    Color.clear.frame(height: 1).id(Self.bottom)
                }
                .padding(16)
            }
            .onChange(of: agent.entries.count) { _, _ in proxy.scrollTo(Self.bottom, anchor: .bottom) }
        }
        .onAppear { settings.loadModels() }
    }

    private static let bottom = "bottom"

    @ViewBuilder private func row(_ kind: AgentEntry.Kind) -> some View {
        switch kind {
        case .user(let text): MessageBubble(message: ChatMessage(id: 0, role: .user, content: text), thinking: false)
        case .reply(let text): MessageBubble(message: ChatMessage(id: 0, role: .assistant, content: text), thinking: false)
        case .change(let change): ChangeRow(change: change)
        case .note(let text): Text(text).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: Mode.agent.symbol).font(.system(size: 28)).foregroundStyle(Mode.agent.tint)
            Text(settings.hasKey ? "Change Flick by asking" : "Add your OpenRouter key to start")
                .font(.system(size: 15, weight: .semibold))
            Text(settings.hasKey ? "Try “Add a quicklink that searches GitHub with gh”." : "Press ⌘, and open the AI tab.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 90)
    }
}

private struct ChangeRow: View {
    let change: AgentChange

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: symbol).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(change.title).font(.system(size: 13, weight: .medium))
                Text(change.detail).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.primary.opacity(0.12)))
    }

    private var symbol: String {
        switch change.kind {
        case .added: return "plus.circle.fill"
        case .updated: return "pencil.circle.fill"
        case .removed: return "minus.circle.fill"
        }
    }

    private var color: Color {
        switch change.kind {
        case .added: return .green
        case .updated: return .blue
        case .removed: return .red
        }
    }
}
