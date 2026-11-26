import AppKit
import FlickCore

final class VideoDownloader {
    var onProgress: (Int?) -> Void = { _ in }

    private static let ytDlpPaths = ["/opt/homebrew/bin/yt-dlp", "/usr/local/bin/yt-dlp"]
    private static let brewPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
    private static let toolsPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

    func download(_ url: URL) {
        guard let ytDlp = Self.executable(in: Self.ytDlpPaths) else {
            Toast.shared.show(.ytDlpMissing)
            return
        }
        let downloads = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        let arguments = VideoDownload.ytDlpArguments(for: url, into: downloads)
        let report: (Int) -> Void = { [weak self] percent in DispatchQueue.main.async { self?.onProgress(percent) } }
        onProgress(0)
        Task.detached {
            var file = await Self.download(ytDlp, arguments: arguments, report: report)
            if file == nil { file = await Self.upgradeAndRetry(ytDlp, arguments: arguments, report: report) }
            await MainActor.run { [weak self, file] in
                self?.onProgress(nil)
                Self.finish(file)
            }
        }
    }

    private static func upgradeAndRetry(_ ytDlp: String, arguments: [String], report: @escaping (Int) -> Void) async -> URL? {
        guard let brew = executable(in: brewPaths) else { return nil }
        await MainActor.run { Toast.shared.show(.updatingYtDlp) }
        let upgrade = makeProcess(brew, arguments: ["upgrade", "yt-dlp"])
        guard (try? upgrade.run()) != nil else { return nil }
        upgrade.waitUntilExit()
        guard upgrade.terminationStatus == 0 else { return nil }
        return await download(ytDlp, arguments: arguments, report: report)
    }

    private static func download(_ ytDlp: String, arguments: [String], report: @escaping (Int) -> Void) async -> URL? {
        let process = makeProcess(ytDlp, arguments: arguments)
        let output = Pipe()
        process.standardOutput = output
        guard (try? process.run()) != nil else { return nil }
        var file: URL?
        do {
            for try await line in output.fileHandleForReading.bytes.lines {
                switch VideoDownload.parse(line) {
                case .progress(let percent): report(percent)
                case .file(let url): file = url
                case nil: break
                }
            }
        } catch {
            return nil
        }
        process.waitUntilExit()
        return process.terminationStatus == 0 ? file : nil
    }

    private static func makeProcess(_ executable: String, arguments: [String]) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.environment = ProcessInfo.processInfo.environment.merging(["PATH": toolsPath]) { _, new in new }
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        return process
    }

    private static func executable(in paths: [String]) -> String? {
        paths.first(where: FileManager.default.isExecutableFile)
    }

    private static func finish(_ file: URL?) {
        guard let file else {
            Toast.shared.show(.downloadFailed)
            return
        }
        Toast.shared.show(.downloaded(file))
        NSWorkspace.shared.activateFileViewerSelecting([file])
    }
}
