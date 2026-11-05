import FlickCore
import Foundation

final class AISettings: ObservableObject {
    private static let modelKey = "aiModelID"

    @Published private(set) var hasKey = Keychain.read() != nil
    @Published var modelID: String? = UserDefaults.standard.string(forKey: modelKey) {
        didSet { UserDefaults.standard.set(modelID, forKey: Self.modelKey) }
    }
    @Published private(set) var models: [AIModel] = []
    @Published private(set) var popularModels: [AIModel] = []
    @Published private(set) var modelsError: String?

    var key: String? { Keychain.read() }

    var modelName: String {
        models.first { $0.id == modelID }?.name ?? modelID ?? "No model"
    }

    func saveKey(_ key: String) {
        Keychain.save(key.trimmingCharacters(in: .whitespacesAndNewlines))
        hasKey = true
    }

    func removeKey() {
        Keychain.delete()
        hasKey = false
    }

    func visibleModels(matching query: String, including modelID: String?) -> [AIModel] {
        ModelCatalog.visible(query: query, popular: popularModels, all: models, includingID: modelID)
    }

    func loadModels() {
        guard models.isEmpty else { return }
        Task { @MainActor in
            do {
                models = try await Self.fetch(OpenRouter.modelsURL).sorted { $0.name < $1.name }
                popularModels = ModelCatalog.merged(try await Self.fetchPopular())
                modelsError = nil
                if modelID == nil { modelID = ModelCatalog.preferredDefault(in: models)?.id }
            } catch {
                modelsError = "Couldn't load models from OpenRouter: \(error.localizedDescription)"
            }
        }
    }

    private static func fetchPopular() async throws -> [[AIModel]] {
        var lists: [[AIModel]] = []
        for category in ModelCatalog.popularCategories {
            lists.append(try await fetch(ModelCatalog.categoryURL(category)))
        }
        return lists
    }

    private static func fetch(_ url: URL) async throws -> [AIModel] {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try ModelCatalog.models(fromJSON: data)
    }
}
