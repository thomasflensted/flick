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

    @Test func decodesOpenRouterList() throws {
        let json = #"{"data":[{"id":"a/b","name":"B","created":5,"context_length":1000}]}"#
        #expect(try ModelCatalog.models(fromJSON: Data(json.utf8)) == [AIModel(id: "a/b", name: "B", created: 5)])
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
