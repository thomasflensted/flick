import FlickCore

enum RunOutcome {
    case done
    case enter(Mode)
    case askArgument(Quicklink)
}

final class ResultRunner {
    let commands: CommandRunner

    init(commands: CommandRunner) {
        self.commands = commands
    }

    func run(_ kind: ResultKind, delivery: Delivery) -> RunOutcome {
        switch kind {
        case .quicklink(let ql, nil) where ql.takesArgument: return .askArgument(ql)
        case .quicklink(let ql, let argument): Launcher.open(ql, argument: argument ?? "")
        case .app(let app): Launcher.open(app)
        case .url(let url): Launcher.open(url)
        case .google(let query): Launcher.open(URLText.googleSearch(query))
        case .command(let command): commands.run(command, delivery: delivery)
        case .mode(let mode): return .enter(mode)
        case .emoji(let emoji): Paster.deliver(emoji.character, delivery)
        case .message: Launcher.revealQuicklinksFile()
        }
        return .done
    }
}
