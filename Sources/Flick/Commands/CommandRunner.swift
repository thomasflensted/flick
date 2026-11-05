import FlickCore

final class CommandRunner {
    let caffeine = Caffeine()

    var available: [Command] { Command.available(isCaffeinated: caffeine.isActive) }

    func run(_ command: Command) {
        switch command {
        case .caffeinate: caffeine.start()
        case .caffeinateFor(let minutes): caffeine.start(minutes: minutes)
        case .decaffeinate: caffeine.stop()
        }
    }
}
