import FlickCore
import SwiftUI

struct ChangeRow: View {
    let change: SettingsChange
    let reverted: Bool
    let canRevert: Bool
    let onRevert: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: symbol).foregroundStyle(reverted ? .secondary : color)
            VStack(alignment: .leading, spacing: 2) {
                Text(change.title).font(.system(size: 13, weight: .medium)).strikethrough(reverted)
                Text(change.detail).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 8)
            revertControl
        }
        .opacity(reverted ? 0.6 : 1)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.primary.opacity(0.12)))
    }

    @ViewBuilder private var revertControl: some View {
        if reverted {
            Text("Reverted").font(.system(size: 12)).foregroundStyle(.secondary)
        } else {
            Button(action: onRevert) {
                Image(systemName: "arrow.uturn.backward").font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderless)
            .disabled(!canRevert)
            .help("Revert this change")
        }
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
