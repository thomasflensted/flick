import Foundation
import Testing
@testable import FlickCore

struct AgentWorkspaceTests {
    private let github = Quicklink(name: "GitHub", link: "https://github.com", keyword: "gh")
    private let email = Snippet(name: "Work email", text: "me@work.com", keyword: "@@w")

    private var workspace: AgentWorkspace { AgentWorkspace(quicklinks: [github], snippets: [email]) }

    private func call(_ tool: AgentTool, _ arguments: String = "{}") -> AgentToolCall {
        AgentToolCall(id: "call_1", name: tool.rawValue, arguments: arguments)
    }

    @Test func addsQuicklinkWithoutID() {
        var workspace = workspace
        let outcome = workspace.perform(call(.saveQuicklink, #"{"name":"Search GitHub","keyword":"ghs","link":"https://github.com/search?q={argument}"}"#))
        #expect(workspace.quicklinks.map(\.name) == ["GitHub", "Search GitHub"])
        #expect(outcome.change == AgentChange(kind: .added, item: "quicklink", name: "Search GitHub",
                                              detail: "ghs · https://github.com/search?q={argument}"))
    }

    @Test func editsQuicklinkInPlaceKeepingItsID() {
        var workspace = workspace
        let outcome = workspace.perform(call(.saveQuicklink, #"{"id":"\#(github.id)","name":"GitHub","link":"https://github.com","openWith":"com.google.Chrome"}"#))
        #expect(workspace.quicklinks.count == 1)
        #expect(workspace.quicklinks[0].id == github.id)
        #expect(workspace.quicklinks[0].openWith == "com.google.Chrome")
        #expect(outcome.change?.kind == .updated)
    }

    @Test func deletesSnippet() {
        var workspace = workspace
        let outcome = workspace.perform(call(.deleteSnippet, #"{"id":"\#(email.id)"}"#))
        #expect(workspace.snippets.isEmpty)
        #expect(outcome.change == AgentChange(kind: .removed, item: "snippet", name: "Work email", detail: "@@w · me@work.com"))
    }

    @Test func reportsUnknownIDWithoutChanging() {
        var workspace = workspace
        let outcome = workspace.perform(call(.deleteQuicklink, #"{"id":"\#(UUID())"}"#))
        #expect(workspace == self.workspace)
        #expect(outcome.change == nil)
        #expect(outcome.output.hasPrefix("Error:"))
    }

    @Test func reportsInvalidArgumentsAndUnknownTools() {
        var workspace = workspace
        let missingLink = workspace.perform(call(.saveQuicklink, #"{"name":"Broken"}"#))
        let unknown = workspace.perform(AgentToolCall(id: "call_1", name: "delete_everything", arguments: "{}"))
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

struct AgentReplyTests {
    @Test func readsToolCalls() throws {
        let json = #"{"choices":[{"message":{"role":"assistant","content":null,"tool_calls":[{"id":"call_1","type":"function","function":{"name":"list_quicklinks","arguments":"{}"}}]}}]}"#
        let message = try AgentReply.message(fromJSON: Data(json.utf8))
        #expect(message.calls == [AgentToolCall(id: "call_1", name: "list_quicklinks", arguments: "{}")])
        #expect(message.text == nil)
    }

    @Test func surfacesErrors() {
        let json = #"{"error":{"message":"No endpoints found that support tool use","code":404}}"#
        #expect(throws: OpenRouterError(errorDescription: "No endpoints found that support tool use")) {
            try AgentReply.message(fromJSON: Data(json.utf8))
        }
    }
}

struct AgentRequestTests {
    private struct Body: Decodable {
        struct Tool: Decodable {
            struct Function: Decodable {
                struct Parameters: Decodable { let required: [String] }
                let name: String
                let parameters: Parameters
            }
            let function: Function
        }
        let tools: [Tool]
        let messages: [AgentMessage]
    }

    private func body(_ messages: [AgentMessage]) throws -> Body {
        let data = try OpenRouter.agentBody(model: AIModel(id: "anthropic/claude-sonnet-5.5", name: "Sonnet", created: 0), messages: messages)
        return try JSONDecoder().decode(Body.self, from: data)
    }

    @Test func sendsEveryToolWithItsRequiredFields() throws {
        let functions = try body([.user("hi")]).tools.map(\.function)
        #expect(functions.map(\.name) == AgentTool.allCases.map(\.rawValue))
        #expect(functions.first { $0.name == "save_quicklink" }?.parameters.required == ["name", "link"])
        #expect(functions.first { $0.name == "list_snippets" }?.parameters.required == [])
    }

    @Test func sendsToolResultsLinkedToTheirCall() throws {
        let message = AgentMessage.tool(callID: "call_1", output: "Deleted.")
        #expect(try body([message]).messages == [message])
    }
}
