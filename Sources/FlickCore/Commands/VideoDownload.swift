import Foundation

public enum VideoDownload {
    static let youTubeHosts: Set<String> = ["youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtu.be"]
    static let progressPrefix = "progress "

    public enum OutputLine: Equatable {
        case progress(percent: Int)
        case file(URL)
    }

    public static func isYouTubeVideo(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased(), youTubeHosts.contains(host) else { return false }
        if host == "youtu.be" { return url.pathComponents.count > 1 }
        return url.path == "/watch" || url.path.hasPrefix("/shorts/") || url.path.hasPrefix("/live/")
    }

    public static func ytDlpArguments(for url: URL, into folder: URL) -> [String] {
        [
            "--no-playlist",
            "--format-sort", "vcodec:h264,res,acodec:m4a",
            "--merge-output-format", "mp4",
            "--paths", folder.path,
            "--output", "%(title)s.%(ext)s",
            "--print", "after_move:filepath",
            "--quiet", "--no-warnings",
            "--progress", "--newline",
            "--progress-template", "download:\(progressPrefix)%(progress._percent)s",
            url.absoluteString,
        ]
    }

    public static func parse(_ line: String) -> OutputLine? {
        guard line.hasPrefix(progressPrefix) else { return line.isEmpty ? nil : .file(URL(fileURLWithPath: line)) }
        return Double(line.dropFirst(progressPrefix.count)).map { .progress(percent: Int($0)) }
    }
}
