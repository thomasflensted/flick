import Foundation

public struct Feedback: Equatable {
    public let text: String
    public let symbol: String

    public static let copied = Feedback(text: "Copied to clipboard", symbol: "doc.on.clipboard.fill")
    public static let sleepAllowed = Feedback(text: "Your Mac can sleep again", symbol: "moon.zzz.fill")

    public static func ejected(_ drive: Drive) -> Feedback {
        Feedback(text: "Ejected \(drive.name)", symbol: "eject.fill")
    }

    public static func ejectFailed(_ drive: Drive) -> Feedback {
        Feedback(text: "Couldn't eject \(drive.name). Close apps using it and try again.", symbol: "exclamationmark.triangle.fill")
    }

    public static func downloaded(_ file: URL) -> Feedback {
        Feedback(text: "Downloaded \(file.deletingPathExtension().lastPathComponent)", symbol: "checkmark.circle.fill")
    }

    public static let downloading = Feedback(text: "Downloading video…", symbol: "arrow.down.circle.fill")
    public static let downloadFailed = Feedback(text: "Couldn't download the video", symbol: "exclamationmark.triangle.fill")
    public static let updatingYtDlp = Feedback(text: "Updating yt-dlp and trying again…", symbol: "arrow.triangle.2.circlepath")
    public static let ytDlpMissing = Feedback(text: "Install yt-dlp to download videos: brew install yt-dlp", symbol: "exclamationmark.triangle.fill")

    public static func after(_ kind: ResultKind, delivered: Delivery?) -> Feedback? {
        if delivered == .copy { return .copied }
        guard case .command(let command) = kind else { return nil }
        switch command {
        case .keepAwake: return Feedback(text: "Your Mac will stay awake", symbol: "sun.max.fill")
        case .keepAwakeFor(let minutes):
            return Feedback(text: "Your Mac will stay awake for \(DurationText.format(minutes: minutes))", symbol: "sun.max.fill")
        case .allowSleep: return .sleepAllowed
        case .loremSentence, .loremParagraph, .tile, .toggleFullScreen, .downloadVideo: return nil
        }
    }
}
