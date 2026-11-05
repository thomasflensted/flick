import FlickCore
import SwiftUI

struct ResultIcon: View {
    let kind: ResultKind
    var size: CGFloat = 26

    var body: some View {
        icon.frame(width: size, height: size)
    }

    @ViewBuilder private var icon: some View {
        switch kind {
        case .app(let app): fileIcon(app.path)
        case .quicklink(let ql, _): quicklinkIcon(ql)
        case .url: symbol("safari", padding: 2).foregroundStyle(.blue)
        case .google: symbol("magnifyingglass")
        case .command(let command): SymbolTile(symbol: command.symbol, color: command.tint)
        case .mode(let mode): SymbolTile(symbol: mode.symbol, color: mode.tint)
        case .emoji(let emoji): Text(emoji.character).font(.system(size: size * 0.8))
        case .snippet: SymbolTile(symbol: Mode.snippets.symbol, color: Mode.snippets.tint)
        case .message: symbol("exclamationmark.triangle.fill", padding: 3).foregroundStyle(.orange)
        }
    }

    @ViewBuilder private func quicklinkIcon(_ ql: Quicklink) -> some View {
        if let host = ql.webHost {
            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64")) { image in
                image.resizable()
            } placeholder: {
                symbol("link")
            }
        } else if let app = Launcher.appURL(for: ql.openWith) {
            fileIcon(app.path)
        } else {
            symbol("link")
        }
    }

    private func fileIcon(_ path: String) -> some View {
        Image(nsImage: IconCache.shared.icon(forFile: path)).resizable()
    }

    private func symbol(_ name: String, padding: CGFloat = 4) -> some View {
        Image(systemName: name).resizable().scaledToFit().padding(padding).foregroundStyle(.secondary)
    }
}
