import Foundation
import Testing
@testable import FlickCore

struct StreamLineTests {
    @Test func readsTextDeltas() {
        #expect(StreamLine.parse(#"data: {"choices":[{"delta":{"content":"Hel"}}]}"#) == .text("Hel"))
    }

    @Test func recognisesEndOfStream() {
        #expect(StreamLine.parse("data: [DONE]") == .done)
    }

    @Test func ignoresCommentsAndEmptyDeltas() {
        #expect(StreamLine.parse(": OPENROUTER PROCESSING") == nil)
        #expect(StreamLine.parse("") == nil)
        #expect(StreamLine.parse(#"data: {"choices":[{"delta":{"role":"assistant"}}]}"#) == nil)
    }

    @Test func surfacesErrorsInStreamAndBody() {
        #expect(StreamLine.parse(#"data: {"error":{"message":"Rate limited","code":429}}"#) == .failed("Rate limited"))
        #expect(StreamLine.parse(#"{"error":{"message":"No auth credentials found","code":401}}"#) == .failed("No auth credentials found"))
    }
}

struct OpenRouterTests {
    @Test func bodyStreamsRolesAndContent() throws {
        let body = try OpenRouter.chatBody(model: "m", messages: [ChatMessage(id: 1, role: .user, content: "Hi")])
        let json = try #require(String(data: body, encoding: .utf8))
        #expect(json.contains(#""stream":true"#))
        #expect(json.contains(#""role":"user""#))
        #expect(!json.contains(#""id""#))
    }

    @Test func requestCarriesKey() throws {
        let request = try OpenRouter.chatRequest(key: "sk-test", model: "m", messages: [])
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
        #expect(request.httpMethod == "POST")
    }
}

struct ModelCatalogTests {
    let models = [
        AIModel(id: "openai/gpt-x", name: "GPT X", created: 300),
        AIModel(id: "anthropic/claude-sonnet-4", name: "Claude Sonnet 4", created: 100),
        AIModel(id: "anthropic/claude-sonnet-5", name: "Claude Sonnet 5", created: 200),
    ]

    @Test func decodesOpenRouterListWithPrice() throws {
        let json = #"{"data":[{"id":"a/b","name":"B","created":5,"pricing":{"prompt":"0.00000009","completion":"0.00000018"}}]}"#
        let model = try #require(ModelCatalog.models(fromJSON: Data(json.utf8)).first)
        #expect(model.id == "a/b")
        #expect(model.priceText == "$0.18 / 1M")
    }

    @Test func freeModelsSayFree() {
        #expect(AIModel(id: "x", name: "X", created: 0, outputPricePerMillion: 0).priceText == "Free")
    }

    @Test func mergesCategoriesWithoutDuplicates() {
        let merged = ModelCatalog.merged([[models[1], models[0]], [models[0], models[2]]])
        #expect(merged.map(\.id) == ["anthropic/claude-sonnet-4", "anthropic/claude-sonnet-5", "openai/gpt-x"])
    }

    @Test func showsPopularWhenNotSearching() {
        let visible = ModelCatalog.visible(query: "", popular: [models[0]], all: models, selectedID: nil)
        #expect(visible.map(\.id) == ["openai/gpt-x"])
    }

    @Test func keepsSelectedModelVisible() {
        let visible = ModelCatalog.visible(query: "", popular: [models[0]], all: models, selectedID: "anthropic/claude-sonnet-4")
        #expect(visible.map(\.id) == ["anthropic/claude-sonnet-4", "openai/gpt-x"])
    }

    @Test func searchesAllModelsButHidesVariants() {
        let all = models + [AIModel(id: "openai/gpt-x:batch", name: "GPT X (batch)", created: 300)]
        let visible = ModelCatalog.visible(query: "gpt", popular: [], all: all, selectedID: nil)
        #expect(visible.map(\.id) == ["openai/gpt-x"])
    }

    @Test func defaultSkipsVariants() {
        let withBatch = models + [AIModel(id: "anthropic/claude-sonnet-5:batch", name: "Batch", created: 999)]
        #expect(ModelCatalog.preferredDefault(in: withBatch)?.id == "anthropic/claude-sonnet-5")
    }

    @Test func defaultsToNewestClaudeSonnet() {
        #expect(ModelCatalog.preferredDefault(in: models)?.id == "anthropic/claude-sonnet-5")
    }

    @Test func fallsBackToFirstModel() {
        #expect(ModelCatalog.preferredDefault(in: [models[0]])?.id == "openai/gpt-x")
    }

    @Test func searchesNamesAndIds() {
        #expect(ModelCatalog.search("gpt", in: models).map(\.id) == ["openai/gpt-x"])
        #expect(ModelCatalog.search("sonnet 5", in: models).first?.id == "anthropic/claude-sonnet-5")
    }
}
