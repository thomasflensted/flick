import FlickCore
import SwiftUI

struct AISettingsView: View {
    @ObservedObject var settings: AISettings
    @State private var newKey = ""
    @State private var modelQuery = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            keySection
            Divider()
            modelSection
        }
        .padding()
        .frame(minWidth: 720, minHeight: 420)
        .onAppear { settings.loadModels() }
    }

    private var keySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OpenRouter API key").font(.headline)
            if settings.hasKey {
                HStack {
                    Label("Saved in your Keychain", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    Spacer()
                    Button("Remove Key", role: .destructive) { settings.removeKey() }
                }
            } else {
                HStack {
                    SecureField("sk-or-…", text: $newKey)
                    Button("Save") { settings.saveKey(newKey); newKey = "" }
                        .disabled(newKey.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Link("Get a key at openrouter.ai", destination: OpenRouter.keysPage).font(.caption)
            }
        }
    }

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Model").font(.headline)
                Spacer()
                Text(settings.modelName).foregroundStyle(.secondary)
            }
            TextField("Search all \(settings.models.count) models…", text: $modelQuery)
            Text(modelQuery.isEmpty ? "Popular models on OpenRouter" : "All matching models")
                .font(.caption).foregroundStyle(.secondary)
            if let error = settings.modelsError {
                Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.caption)
            }
            List(settings.visibleModels(matching: modelQuery), selection: $settings.modelID) { model in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(model.name)
                        Text(model.id).foregroundStyle(.secondary).font(.caption)
                    }
                    Spacer()
                    Text(model.priceText ?? "").foregroundStyle(.secondary).font(.caption.monospacedDigit())
                }
                .tag(Optional(model.id))
            }
        }
    }
}
