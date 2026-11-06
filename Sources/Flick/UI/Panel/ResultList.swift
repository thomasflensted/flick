import FlickCore
import SwiftUI

struct ResultList: View {
    @ObservedObject var model: SearchModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(model.results.enumerated()), id: \.element.id) { index, item in
                        ResultRow(item: item, selected: index == model.selected, subtitle: model.liveSubtitle(for: item),
                                  running: model.isRunning(item.kind))
                            .id(item.id)
                            .onTapGesture { model.activate(index) }
                    }
                }
                .padding(8)
            }
            .onChange(of: model.selected) { _, index in scroll(proxy, to: index) }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, to index: Int) {
        if model.results.indices.contains(index) { proxy.scrollTo(model.results[index].id) }
    }
}
