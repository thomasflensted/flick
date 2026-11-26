import FlickCore

final class CommandRunner {
    let keepAwake = KeepAwake()

    var available: [Command] { Command.available(isKeepingAwake: keepAwake.isActive) }

    func run(_ command: Command) {
        switch command {
        case .keepAwake: keepAwake.start()
        case .keepAwakeFor(let minutes): keepAwake.start(minutes: minutes)
        case .allowSleep: keepAwake.stop()
        case .loremSentence, .loremParagraph: break
        case .tile(let tile): WindowTiler.tile(tile)
        case .toggleFullScreen: WindowTiler.toggleFullScreen()
        }
    }
}
