import FlickCore

final class CommandRunner {
    let keepAwake = KeepAwake()

    var available: [Command] { Command.available(isKeepingAwake: keepAwake.isActive) }

    func run(_ command: Command, delivery: Delivery) -> Delivery? {
        switch command {
        case .keepAwake: keepAwake.start()
        case .keepAwakeFor(let minutes): keepAwake.start(minutes: minutes)
        case .allowSleep: keepAwake.stop()
        case .loremSentence: return Paster.deliver(LoremIpsum.sentence(), delivery)
        case .loremParagraph: return Paster.deliver(LoremIpsum.paragraph(), delivery)
        case .tile(let tile): WindowTiler.tile(tile)
        }
        return nil
    }
}
