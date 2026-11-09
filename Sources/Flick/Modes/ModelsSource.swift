import FlickCore

final class ModelsSource: ModeSource {
    var onUpdate: () -> Void {
        get { settings.onModelsLoaded }
        set { settings.onModelsLoaded = newValue }
    }
    private let settings: AISettings

    init(settings: AISettings) {
        self.settings = settings
    }

    func enter() {
        settings.loadModels()
    }

    func results(for query: String) -> [ResultItem] {
        ModelCatalog.results(for: query, popular: settings.popularModels, all: settings.models, currentID: settings.modelID)
    }
}
