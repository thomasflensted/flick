import FlickCore
import Foundation

enum OpenPullRequests {
    private static let ghPaths = ["/opt/homebrew/bin/gh", "/usr/local/bin/gh"]

    static func fetch() -> PullRequestsState {
        guard let gh = ghPaths.first(where: FileManager.default.isExecutableFile) else {
            return .failed("Install the GitHub CLI (gh) to see your pull requests")
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gh)
        process.arguments = PullRequests.ghArguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return .failed("Couldn't run gh") }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0, let pullRequests = PullRequests.decode(data) else {
            return .failed("Couldn't load pull requests. Is gh logged in? Run gh auth login")
        }
        return .loaded(pullRequests)
    }
}
