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
        case .askAI: SymbolTile(symbol: Mode.chat.symbol, color: Mode.chat.tint)
        case .command(let command): SymbolTile(symbol: command.symbol, color: command.tint)
        case .mode(let mode): SymbolTile(symbol: mode.symbol, color: mode.tint)
        case .emoji(let emoji): Text(emoji.character).font(.system(size: size * 0.8))
        case .snippet: SymbolTile(symbol: Mode.snippets.symbol, color: Mode.snippets.tint)
        case .clip(let entry): clipIcon(entry)
        case .conversion: SymbolTile(symbol: "dollarsign.arrow.circlepath", color: .green)
        case .time: SymbolTile(symbol: "globe", color: .teal)
        case .translation: SymbolTile(symbol: Mode.translate.symbol, color: Mode.translate.tint)
        case .server: SymbolTile(symbol: Mode.servers.symbol, color: Mode.servers.tint)
        case .drive(let drive): fileIcon(drive.url.path)
        case .model: SymbolTile(symbol: Mode.models.symbol, color: Mode.models.tint)
        case .hint: symbol("info.circle", padding: 3)
        case .message: symbol("exclamationmark.triangle.fill", padding: 3).foregroundStyle(.orange)
        }
    }

    @ViewBuilder private func quicklinkIcon(_ ql: Quicklink) -> some View {
        if let host = ql.webHost {
            FaviconView(host: host) { symbol("link") }
        } else if let app = Launcher.appURL(for: ql.openWith) {
            fileIcon(app.path)
        } else {
            symbol("link")
        }
    }

    @ViewBuilder private func clipIcon(_ entry: ClipEntry) -> some View {
        if let path = entry.appPath {
            fileIcon(path)
        } else {
            SymbolTile(symbol: Mode.clipboard.symbol, color: Mode.clipboard.tint)
        }
    }

    private func fileIcon(_ path: String) -> some View {
        Image(nsImage: IconCache.shared.icon(forFile: path)).resizable()
    }

    private func symbol(_ name: String, padding: CGFloat = 4) -> some View {
        Image(systemName: name).resizable().scaledToFit().padding(padding).foregroundStyle(.secondary)
    }
}
