import AppKit

enum RunningApps {
    static func paths() -> Set<String> {
        Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleURL?.path })
    }
}
