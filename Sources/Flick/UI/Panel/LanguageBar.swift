import FlickCore
import SwiftUI

struct LanguageBar: View {
    @ObservedObject var translator: Translator
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            LanguageMenu(title: sourceTitle, selection: translator.pair.source, autoTitle: "Detect language") {
                translator.pair.source = $0
                onChange()
            }
            Button(action: swap) {
                Image(systemName: "arrow.left.arrow.right").font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("Swap languages (⌘S)")
            LanguageMenu(title: targetTitle, selection: translator.pair.target, autoTitle: "Automatic") {
                translator.pair.target = $0
                onChange()
            }
        }
    }

    private func swap() {
        translator.swap()
        onChange()
    }

    private var sourceTitle: String {
        if let source = translator.pair.source { return name(source) }
        return translator.translation.map { "\(name($0.source)) (detected)" } ?? "Detect language"
    }

    private var targetTitle: String {
        name(translator.translation?.target ?? translator.pair.firstTarget(translator.languages))
    }

    private func name(_ code: String) -> String { Language.name(of: code, in: .current) }
}

struct LanguageMenu: View {
    let title: String
    let selection: String?
    let autoTitle: String
    let onSelect: (String?) -> Void

    var body: some View {
        Menu {
            item(autoTitle, code: nil)
            Divider()
            ForEach(Language.choices(in: .current), id: \.self) { code in
                item(Language.name(of: code, in: .current), code: code)
            }
        } label: {
            Text(title).font(.system(size: 12, weight: .medium))
        }
        .menuStyle(.button)
        .controlSize(.small)
        .fixedSize()
    }

    private func item(_ title: String, code: String?) -> some View {
        Button { onSelect(code) } label: {
            if selection == code { Label(title, systemImage: "checkmark") } else { Text(title) }
        }
    }
}
