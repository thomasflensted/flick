import Foundation

func removeClaudeSessionVariables() {
    for name in ProcessInfo.processInfo.environment.keys where name == "CLAUDECODE" || name.hasPrefix("CLAUDE_") {
        unsetenv(name)
    }
}
