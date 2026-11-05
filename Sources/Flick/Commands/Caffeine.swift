import Foundation

final class Caffeine {
    var onChange: (Bool) -> Void = { _ in }
    private var activity: NSObjectProtocol?
    private var timer: Timer?

    var isActive: Bool { activity != nil }

    func start(minutes: Int? = nil) {
        stop()
        activity = ProcessInfo.processInfo.beginActivity(options: [.idleDisplaySleepDisabled, .userInitiated],
                                                         reason: "Caffeinate")
        if let minutes {
            timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in self?.stop() }
        }
        onChange(true)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        guard let activity else { return }
        ProcessInfo.processInfo.endActivity(activity)
        self.activity = nil
        onChange(false)
    }
}
