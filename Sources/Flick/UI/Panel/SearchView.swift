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
            resultList
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
            TextField("Search apps, quicklinks, or Google…", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: Self.queryFontSize))
                .focused($focus, equals: .query)
                .frame(width: queryWidth, alignment: .leading)
            if let link = model.inlineArgumentLink {
                ResultIcon(kind: .quicklink(link, argument: nil), size: 22)
                ArgumentField(link: link, text: $model.argument, active: model.argumentTarget != nil, focus: $focus)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
    }

    private var queryWidth: CGFloat? {
        model.inlineArgumentLink == nil ? nil : textWidth(model.query, fontSize: Self.queryFontSize) + 6
    }

    private var resultList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(model.results.enumerated()), id: \.element.id) { index, item in
                        ResultRow(item: item, selected: index == model.selected, subtitle: model.liveSubtitle(for: item))
                            .id(item.id)
                            .onTapGesture { model.activate(index) }
                    }
                }
                .padding(8)
            }
            .onChange(of: model.selected) { _, index in
                if model.results.indices.contains(index) { proxy.scrollTo(model.results[index].id) }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Spacer()
            KeyHint(key: "↵", label: "Open")
            KeyHint(key: "⇥", label: model.argumentTarget == nil ? "Add query" : "Back to search")
            KeyHint(key: "⌘,", label: "Manage quicklinks")
            KeyHint(key: "esc", label: "Close")
        }
        .padding(.horizontal, 14)
        .frame(height: 30)
    }

    private func syncFocusToModel(_ old: Field?, _ new: Field?) {
        if new == .argument, model.argumentTarget == nil, let link = model.inlineArgumentLink { model.enterArgument(link) }
        if new == .query, model.argumentTarget != nil { model.exitArgument() }
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
