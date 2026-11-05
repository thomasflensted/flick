import FlickCore
import SwiftUI

struct EmojiGrid: View {
    @ObservedObject var model: SearchModel
    let columns: Int

    private static let cellHeight: CGFloat = 64
    private static let emojiSize: CGFloat = 34

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columns), spacing: 4) {
                    ForEach(Array(model.results.enumerated()), id: \.element.id) { index, item in
                        cell(item, selected: index == model.selected)
                            .id(item.id)
                            .onTapGesture { model.activate(index) }
                    }
                }
                .padding(10)
            }
            .onChange(of: model.selected) { _, index in
                if model.results.indices.contains(index) { proxy.scrollTo(model.results[index].id) }
            }
        }
    }

    private func cell(_ item: ResultItem, selected: Bool) -> some View {
        Text(character(of: item))
            .font(.system(size: Self.emojiSize))
            .frame(maxWidth: .infinity)
            .frame(height: Self.cellHeight)
            .background(RoundedRectangle(cornerRadius: 10).fill(selected ? Color.primary.opacity(0.14) : Color.primary.opacity(0.03)))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? Color.accentColor.opacity(0.7) : .clear, lineWidth: 1.5))
            .contentShape(Rectangle())
            .help(item.title)
    }

    private func character(of item: ResultItem) -> String {
        if case .emoji(let emoji) = item.kind { return emoji.character }
        return ""
    }
}
