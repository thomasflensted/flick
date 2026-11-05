import FlickCore
import SwiftUI

struct ResultRow: View {
    let item: ResultItem
    let selected: Bool
    var subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            ResultIcon(kind: item.kind)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(.system(size: 14, weight: .medium)).lineLimit(1)
                if showsSubtitle {
                    Text(subtitle ?? item.subtitle)
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .lineLimit(1).truncationMode(.middle)
                }
            }
            Spacer(minLength: 8)
            Text(badge).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(RoundedRectangle(cornerRadius: 8).fill(selected ? Color.primary.opacity(0.1) : .clear))
        .contentShape(Rectangle())
    }

    private var showsSubtitle: Bool {
        if case .app = item.kind { return false }
        return true
    }

    private var badge: String {
        switch item.kind {
        case .quicklink: return "Quicklink"
        case .app: return "Application"
        case .url: return "URL"
        case .google: return "Web"
        case .command: return "Command"
        case .message: return ""
        }
    }
}
