import FlickCore
import SwiftUI

struct ResultRow: View {
    let item: ResultItem
    let selected: Bool
    var subtitle: String?
    var running = false

    var body: some View {
        HStack(spacing: 12) {
            ResultIcon(kind: item.kind).overlay(alignment: .bottom) {
                if running { Circle().fill(.secondary).frame(width: 4, height: 4).offset(y: 6) }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(.system(size: 14, weight: .medium)).lineLimit(titleLines)
                    .fixedSize(horizontal: false, vertical: true)
                if !shownSubtitle.isEmpty {
                    Text(shownSubtitle)
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .lineLimit(1).truncationMode(.middle)
                }
            }
            Spacer(minLength: 8)
            Text(badge).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .background(RoundedRectangle(cornerRadius: 8).fill(selected ? Color.primary.opacity(0.1) : .clear))
        .contentShape(Rectangle())
    }

    private var titleLines: Int {
        if case .translation = item.kind { return 12 }
        return 1
    }

    private var shownSubtitle: String { subtitle ?? item.subtitle }

    private var badge: String {
        switch item.kind {
        case .quicklink: return "Quicklink"
        case .app: return "Application"
        case .url: return "URL"
        case .google: return "Web"
        case .askAI: return "AI"
        case .command, .mode: return "Command"
        case .emoji: return ""
        case .snippet: return "Snippet"
        case .clip: return ""
        case .conversion: return "Currency"
        case .translation: return "Google Translate"
        case .server: return "Server"
        case .hint: return ""
        case .message: return ""
        }
    }
}
