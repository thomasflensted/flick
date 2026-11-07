import FlickCore

final class EditableSettings {
    private let library: Library
    private let ai: AISettings
    private let translator: Translator

    init(library: Library, ai: AISettings, translator: Translator) {
        self.library = library
        self.ai = ai
        self.translator = translator
    }

    func reloadProblem() -> String? {
        library.reloadIfChanged()
        return (library.quicklinks.loadError ?? library.snippets.loadError).map { "\($0) Fix the file before changing settings." }
    }

    var current: SettingsWorkspace {
        SettingsWorkspace(quicklinks: library.quicklinks.items, snippets: library.snippets.items, modelID: ai.modelID,
                          translatePair: translator.pair, launchAtLogin: LoginItem.isEnabled, models: ai.models)
    }

    func save(_ workspace: SettingsWorkspace) {
        if workspace.quicklinks != library.quicklinks.items { library.quicklinks.replace(with: workspace.quicklinks) }
        if workspace.snippets != library.snippets.items { library.snippets.replace(with: workspace.snippets) }
        if workspace.modelID != ai.modelID { ai.modelID = workspace.modelID }
        if workspace.translatePair != translator.pair { translator.pair = workspace.translatePair }
        if workspace.launchAtLogin != LoginItem.isEnabled { LoginItem.toggle() }
    }
}
