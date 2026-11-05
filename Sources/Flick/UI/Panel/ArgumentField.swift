import FlickCore
import SwiftUI

struct ArgumentField: View {
    let link: Quicklink
    @Binding var text: String
    let active: Bool
    var focus: FocusState<Field?>.Binding

    private static let fontSize: CGFloat = 16
    private static let maxWidth: CGFloat = 400

    var body: some View {
        TextField(link.argumentLabel, text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: Self.fontSize))
            .focused(focus, equals: .argument)
            .padding(.horizontal, 10)
            .frame(width: width, height: 32)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(active ? 0.1 : 0.05)))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(active ? Color.accentColor.opacity(0.8) : Color.primary.opacity(0.2), lineWidth: active ? 1.5 : 1))
            .animation(.easeOut(duration: 0.12), value: active)
    }

    private var width: CGFloat {
        let content = max(textWidth(link.argumentLabel, fontSize: Self.fontSize), textWidth(text, fontSize: Self.fontSize))
        return min(content + 22, Self.maxWidth)
    }
}
