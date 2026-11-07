import FlickCore
import SwiftUI

struct SearchView: View {
    @ObservedObject var model: SearchModel
    @FocusState private var focus: Field?

    private static let queryFontSize: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            results
            Divider()
            footer
        }
        .frame(width: PanelController.size.width, height: PanelController.size.height)
        .background(VisualEffect())
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.12)))
        .onChange(of: model.focusRequest) { _, _ in focus = model.focus }
        .onChange(of: focus, syncFocusToModel)
        .onAppear { focus = .query }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.system(size: 18)).foregroundStyle(.secondary)
            if model.mode != .root { ModeChip(title: model.mode.chip) }
            TextField(model.mode.placeholder, text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: Self.queryFontSize))
                .focused($focus, equals: .query)
                .frame(width: queryWidth, alignment: .leading)
            if let link = model.inlineArgumentLink {
                ResultIcon(kind: .quicklink(link, argument: nil), size: 22)
                ArgumentField(link: link, text: $model.argument, active: model.argumentTarget != nil, focus: $focus)
                Spacer(minLength: 0)
            }
            if model.mode == .translate {
                LanguageBar(translator: model.translator, onChange: model.translateAgain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
    }

    private var queryWidth: CGFloat? {
        model.inlineArgumentLink == nil ? nil : textWidth(model.query, fontSize: Self.queryFontSize) + 6
    }

    @ViewBuilder private var results: some View {
        if model.mode == .chat {
            ChatView(chat: model.chat, settings: model.chat.settings)
        } else if let columns = model.mode.gridColumns {
            EmojiGrid(model: model, columns: columns)
        } else {
            ResultList(model: model)
        }
    }

    private var footer: some View {
        HStack(spacing: 16) {
            if model.movesInGrid, let title = model.selectedTitle {
                Text(title).font(.system(size: 12, weight: .medium)).lineLimit(1)
            }
            if model.mode == .chat {
                Button { model.enter(.models) } label: {
                    Text(model.chat.settings.modelName).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary).lineLimit(1)
                }
                .buttonStyle(.plain)
                .help("Switch model (⌘M)")
            }
            Spacer()
            if model.mode == .chat {
                KeyHint(key: "↵", label: "Send")
                KeyHint(key: "⌘N", label: "New chat")
                KeyHint(key: "⌘M", label: "Model")
            } else if model.mode == .models {
                KeyHint(key: "↵", label: "Use model")
            } else if model.selectedProducesText {
                KeyHint(key: "↵", label: "Paste")
                KeyHint(key: "⌘↵", label: "Copy")
            } else {
                KeyHint(key: "↵", label: "Open")
            }
            if model.mode == .translate {
                KeyHint(key: "⌘S", label: "Swap")
            }
            if let label = model.mode.removeLabel {
                KeyHint(key: "⌘⌫", label: label)
            }
            if model.mode == .root {
                KeyHint(key: "⇥", label: model.tabHint)
                KeyHint(key: "⌘,", label: "Settings")
            }
            KeyHint(key: "esc", label: model.mode == .root ? "Close" : "Back")
        }
        .padding(.horizontal, 14)
        .frame(height: 30)
    }

    private func syncFocusToModel(_ old: Field?, _ new: Field?) {
        if new == .argument, model.argumentTarget == nil, let link = model.inlineArgumentLink { model.enterArgument(link) }
        if new == .query, model.argumentTarget != nil { model.exitArgument() }
    }
}

struct ModeChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.2)))
    }
}

struct KeyHint: View {
    let key: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(key).font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.08)))
            Text(label).font(.system(size: 11))
        }
        .foregroundStyle(.secondary)
    }
}
