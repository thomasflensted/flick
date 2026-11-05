import FlickCore

final class CommandRunner {
    let keepAwake = KeepAwake()

    var available: [Command] { Command.available(isKeepingAwake: keepAwake.isActive) }

    func run(_ command: Command) {
        switch command {
        case .keepAwake: keepAwake.start()
        case .keepAwakeFor(let minutes): keepAwake.start(minutes: minutes)
        case .allowSleep: keepAwake.stop()
        case .loremSentence: Paster.paste(LoremIpsum.sentence())
        case .loremParagraph: Paster.paste(LoremIpsum.paragraph())
        }
    }
}
