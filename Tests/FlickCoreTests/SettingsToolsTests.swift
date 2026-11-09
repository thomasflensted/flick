import Foundation
import Testing
@testable import FlickCore

struct SettingsWorkspaceTests {
    private let github = Quicklink(name: "GitHub", link: "https://github.com", keyword: "gh")
    private let email = Snippet(name: "Work email", text: "me@work.com", keyword: "@@w")

    private var workspace: SettingsWorkspace { SettingsWorkspace(quicklinks: [github], snippets: [email]) }

    private func call(_ tool: SettingsTool, _ arguments: String = "{}") -> ToolCall {
        ToolCall(id: "call_1", name: tool.name, arguments: arguments)
    }

    @Test func addsQuicklinkWithoutID() {
        var workspace = workspace
        let result = workspace.perform(call(.saveQuicklink, #"{"name":"Search GitHub","keyword":"ghs","link":"https://github.com/search?q={argument}"}"#))
        #expect(workspace.quicklinks.map(\.name) == ["GitHub", "Search GitHub"])
        #expect(result.callID == "call_1")
        #expect(result.change?.title == "Added quicklink Search GitHub")
        #expect(result.change?.detail == "ghs · https://github.com/search?q={argument}")
    }

    @Test func editsQuicklinkInPlaceKeepingItsID() {
        var workspace = workspace
        let result = workspace.perform(call(.saveQuicklink, #"{"id":"\#(github.id)","name":"GitHub","link":"https://github.com","openWith":"com.google.Chrome"}"#))
        #expect(workspace.quicklinks.count == 1)
        #expect(workspace.quicklinks[0].id == github.id)
        #expect(workspace.quicklinks[0].openWith == "com.google.Chrome")
        #expect(result.change?.kind == .updated)
    }

    @Test func deletesSnippet() {
        var workspace = workspace
        let result = workspace.perform(call(.deleteSnippet, #"{"id":"\#(email.id)"}"#))
        #expect(workspace.snippets.isEmpty)
        #expect(result.change?.title == "Removed snippet Work email")
        #expect(result.change?.detail == "@@w · me@work.com")
    }

    @Test func revertsAnAddition() throws {
        var workspace = workspace
        let change = try #require(workspace.perform(call(.saveSnippet, #"{"name":"Test","text":"hi"}"#)).change)
        workspace.revert(change)
        #expect(workspace == self.workspace)
    }

    @Test func revertsAnEditToThePreviousVersion() throws {
        var workspace = workspace
        let change = try #require(workspace.perform(call(.saveQuicklink, #"{"id":"\#(github.id)","name":"Hub","link":"https://github.com"}"#)).change)
        workspace.revert(change)
        #expect(workspace == self.workspace)
    }

    @Test func revertsARemoval() throws {
        var workspace = workspace
        let change = try #require(workspace.perform(call(.deleteQuicklink, #"{"id":"\#(github.id)"}"#)).change)
        workspace.revert(change)
        #expect(workspace == self.workspace)
    }

    @Test func reportsUnknownIDWithoutChanging() {
        var workspace = workspace
        let result = workspace.perform(call(.deleteQuicklink, #"{"id":"\#(UUID())"}"#))
        #expect(workspace == self.workspace)
        #expect(result.change == nil)
        #expect(result.output.hasPrefix("Error:"))
    }

    @Test func reportsInvalidArgumentsAndUnknownTools() {
        var workspace = workspace
        let missingLink = workspace.perform(call(.saveQuicklink, #"{"name":"Broken"}"#))
        let unknown = workspace.perform(ToolCall(id: "call_1", name: "delete_everything", arguments: "{}"))
        #expect(workspace == self.workspace)
        #expect(missingLink.output.hasPrefix("Error:"))
        #expect(unknown.output == "Error: There is no tool called delete_everything.")
    }

    @Test func listsItemsWithIDsForTheModel() throws {
        var workspace = workspace
        let output = workspace.perform(call(.listQuicklinks)).output
        let listed = try JSONDecoder().decode([Quicklink].self, from: Data(output.utf8))
        #expect(listed == [github])
    }
}

struct AppSettingsToolTests {
    private let sonnet = AIModel(id: "anthropic/claude-sonnet-5", name: "Claude Sonnet 5", created: 0, supportsTools: true)
    private let gpt = AIModel(id: "openai/gpt-x", name: "GPT X", created: 0)

    private var workspace: SettingsWorkspace {
        SettingsWorkspace(quicklinks: [], snippets: [], modelID: gpt.id, models: [sonnet, gpt])
    }

    private func call(_ tool: SettingsTool, _ arguments: String = "{}") -> ToolCall {
        ToolCall(id: "call_1", name: tool.name, arguments: arguments)
    }

    @Test func findsModelsByName() {
        var workspace = workspace
        let output = workspace.perform(call(.findModels, #"{"query":"sonnet"}"#)).output
        #expect(output.contains(sonnet.id))
        #expect(!output.contains(gpt.id))
    }

    @Test func switchesModelAndRevertsToThePreviousOne() throws {
        var workspace = workspace
        let change = try #require(workspace.perform(call(.setModel, #"{"id":"\#(sonnet.id)"}"#)).change)
        #expect(workspace.modelID == sonnet.id)
        #expect(change.title == "Updated AI model")
        #expect(change.detail == "Claude Sonnet 5")
        workspace.revert(change)
        #expect(workspace.modelID == gpt.id)
    }

    @Test func rejectsUnknownModels() {
        var workspace = workspace
        let result = workspace.perform(call(.setModel, #"{"id":"made/up"}"#))
        #expect(workspace.modelID == gpt.id)
        #expect(result.output.hasPrefix("Error:"))
    }

    @Test func setsTranslateLanguagesLeavingSourceAutomatic() throws {
        var workspace = workspace
        let change = try #require(workspace.perform(call(.setTranslateLanguages, #"{"target":"es"}"#)).change)
        #expect(workspace.translatePair == TranslatePair(source: nil, target: "es"))
        #expect(change.detail == "Detected language → Spanish")
        workspace.revert(change)
        #expect(workspace.translatePair == TranslatePair())
    }

    @Test func rejectsUnsupportedLanguages() {
        var workspace = workspace
        let result = workspace.perform(call(.setTranslateLanguages, #"{"source":"xx","target":"es"}"#))
        #expect(workspace.translatePair == TranslatePair())
        #expect(result.output.hasPrefix("Error: unsupported language xx."))
    }

    @Test func togglesLaunchAtLogin() throws {
        var workspace = workspace
        let change = try #require(workspace.perform(call(.setLaunchAtLogin, #"{"enabled":true}"#)).change)
        #expect(workspace.launchAtLogin)
        #expect(change.title == "Updated Launch at login")
        workspace.revert(change)
        #expect(!workspace.launchAtLogin)
    }

    @Test func setsSyncFolderAndRevertsToLocal() throws {
        var workspace = workspace
        let change = try #require(workspace.perform(call(.setSyncFolder, #"{"path":"/Users/me/iCloud/Flick"}"#)).change)
        #expect(workspace.syncFolder == "/Users/me/iCloud/Flick")
        #expect(change.title == "Updated Sync folder")
        workspace.revert(change)
        #expect(workspace.syncFolder == nil)
    }

    @Test func rejectsRelativeSyncFolders() {
        var workspace = workspace
        let result = workspace.perform(call(.setSyncFolder, #"{"path":"Flick"}"#))
        #expect(workspace.syncFolder == nil)
        #expect(result.output.hasPrefix("Error:"))
    }

    private struct Current: Decodable {
        let model: String?
        let translate: String
        let launchAtLogin: Bool
        let syncFolder: String?
        let cloudFolders: [String]
    }

    @Test func reportsCurrentSettingsSpellingOutDetectedSource() throws {
        var workspace = SettingsWorkspace(quicklinks: [], snippets: [], modelID: gpt.id, translatePair: TranslatePair(target: "en"),
                                          cloudFolders: ["/Users/me/Dropbox"])
        let output = workspace.perform(call(.getSettings)).output
        let current = try JSONDecoder().decode(Current.self, from: Data(output.utf8))
        #expect(current.model == gpt.id)
        #expect(current.translate == "Detected language → English")
        #expect(!current.launchAtLogin)
        #expect(current.syncFolder == nil)
        #expect(current.cloudFolders == ["/Users/me/Dropbox"])
    }
}

struct ToolCallStreamTests {
    @Test func readsToolCallDeltas() {
        let line = #"data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"list_quicklinks","arguments":""}}]}}]}"#
        #expect(StreamLine.parse(line) == [.toolCall(ToolCallDelta(index: 0, id: "call_1", name: "list_quicklinks", arguments: ""))])
    }

    @Test func assemblesCallsFromChunks() {
        var assembler = ToolCallAssembler()
        assembler.add(ToolCallDelta(index: 0, id: "call_1", name: "delete_snippet", arguments: #"{"id":"#))
        assembler.add(ToolCallDelta(index: 1, id: "call_2", name: "list_quicklinks"))
        assembler.add(ToolCallDelta(index: 0, arguments: #""x"}"#))
        #expect(assembler.calls == [
            ToolCall(id: "call_1", name: "delete_snippet", arguments: #"{"id":"x"}"#),
            ToolCall(id: "call_2", name: "list_quicklinks", arguments: "{}"),
        ])
    }
}

struct ChatToolsRequestTests {
    private struct Body: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String?
            let tool_call_id: String?
        }
        struct Tool: Decodable {
            struct Function: Decodable {
                struct Parameters: Decodable { let required: [String] }
                let name: String
                let parameters: Parameters
            }
            let function: Function
        }
        let tools: [Tool]?
        let messages: [Message]
    }

    private let toolModel = AIModel(id: "anthropic/claude-sonnet-5.5", name: "Sonnet", created: 0, supportsTools: true)

    private func body(_ model: AIModel, _ messages: [ChatMessage]) throws -> Body {
        try JSONDecoder().decode(Body.self, from: OpenRouter.chatBody(model: model, messages: messages))
    }

    @Test func toolModelsGetEveryToolAndTheSettingsPrompt() throws {
        let body = try body(toolModel, [ChatMessage(id: 0, role: .user, content: "hi")])
        let functions = try #require(body.tools).map(\.function)
        #expect(functions.map(\.name) == SettingsTool.all.map(\.name))
        #expect(functions.first { $0.name == "save_quicklink" }?.parameters.required == ["name", "link"])
        #expect(body.messages.map(\.role) == ["system", "user"])
    }

    @Test func otherModelsAreToldTheyCannotChangeSettings() throws {
        let body = try body(AIModel(id: "m", name: "M", created: 0), [ChatMessage(id: 0, role: .user, content: "hi")])
        #expect(body.tools == nil)
        #expect(body.messages.map(\.role) == ["system", "user"])
        #expect(body.messages[0].content == ChatPrompt.withoutTools)
    }

    @Test func sendsToolResultsAfterTheirCallAndMentionsReverts() throws {
        var answer = ChatMessage(id: 1, role: .assistant, content: "")
        answer.toolCalls = [ToolCall(id: "call_1", name: "delete_snippet", arguments: "{}")]
        answer.toolResults = [ToolResult(callID: "call_1", output: "Deleted.")]
        answer.toolResults[0].isReverted = true
        let messages = try body(toolModel, [answer]).messages
        #expect(messages.map(\.role) == ["system", "assistant", "tool"])
        #expect(messages[1].content == nil)
        #expect(messages[2].tool_call_id == "call_1")
        #expect(messages[2].content == "Deleted. \(ChatPrompt.revertedNote)")
    }

    @Test func decodesToolSupport() throws {
        let json = #"{"data":[{"id":"a/b","name":"B","created":5,"supported_parameters":["tools","temperature"]}]}"#
        #expect(try ModelCatalog.models(fromJSON: Data(json.utf8)).first?.supportsTools == true)
    }
}
