import Foundation

public enum SettingsAction: Equatable {
    case listQuicklinks
    case saveQuicklink(Quicklink)
    case deleteQuicklink(UUID)
    case listSnippets
    case saveSnippet(Snippet)
    case deleteSnippet(UUID)
    case getSettings
    case findModels(String)
    case setModel(String?)
    case setTranslateLanguages(TranslatePair)
    case setLaunchAtLogin(Bool)
    case setSyncFolder(String?)
}
