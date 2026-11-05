import FlickCore

final class ResultRunner {
    let commands: CommandRunner

    init(commands: CommandRunner) {
        self.commands = commands
    }

    func run(_ kind: ResultKind) {
        switch kind {
        case .quicklink(let ql, let argument): Launcher.open(ql, argument: argument ?? "")
        case .app(let app): Launcher.open(app)
        case .url(let url): Launcher.open(url)
        case .google(let query): Launcher.open(URLText.googleSearch(query))
        case .command(let command): commands.run(command)
        case .message: Launcher.revealQuicklinksFile()
        }
    }
}
