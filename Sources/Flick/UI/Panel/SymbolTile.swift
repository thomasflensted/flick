import FlickCore
import SwiftUI

struct SymbolTile: View {
    let symbol: String
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: geometry.size.width * 0.24)
                .fill(LinearGradient(colors: [color.opacity(0.85), color], startPoint: .top, endPoint: .bottom))
                .overlay(
                    Image(systemName: symbol)
                        .font(.system(size: geometry.size.width * 0.52, weight: .semibold))
                        .foregroundStyle(.white))
        }
    }
}

extension Command {
    var tint: Color {
        switch self {
        case .keepAwake, .keepAwakeFor: return .orange
        case .allowSleep: return .indigo
        case .loremSentence, .loremParagraph: return .teal
        }
    }
}

extension Mode {
    var tint: Color {
        switch self {
        case .root: return .gray
        case .emoji: return .yellow
        case .snippets: return .pink
        }
    }
}
