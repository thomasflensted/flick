import FlickCore

enum RunOutcome {
    case done(delivered: Delivery?)
    case enter(Mode)
    case askArgument(Quicklink)
    case ask(String)
    case useModel(AIModel)
    case stay
}

final class ResultRunner {
    let commands: CommandRunner

    init(commands: CommandRunner) {
        self.commands = commands
    }

    func run(_ kind: ResultKind, delivery: Delivery) -> RunOutcome {
        let outcome = perform(kind, delivery: delivery)
        if case .done(let delivered) = outcome, let feedback = Feedback.after(kind, delivered: delivered) {
            Toast.shared.show(feedback)
        }
        return outcome
    }

    private func perform(_ kind: ResultKind, delivery: Delivery) -> RunOutcome {
        if let text = kind.text(locale: .current) { return .done(delivered: Paster.deliver(text, delivery)) }
        switch kind {
        case .quicklink(let ql, nil) where ql.takesArgument: return .askArgument(ql)
        case .quicklink(let ql, let argument): Launcher.open(ql, argument: argument ?? "")
        case .app(let app): Launcher.open(app)
        case .url(let url): Launcher.open(url)
        case .google(let query): Launcher.open(URLText.googleSearch(query))
        case .askAI(let question): return .ask(question)
        case .command(let command): commands.run(command)
        case .mode(let mode): return .enter(mode)
        case .emoji, .snippet, .clip, .conversion, .time, .translation: break
        case .weather(let report): Launcher.open(YrAPI.pageURL(report.place))
        case .server(let server): if let url = server.url { Launcher.open(url) }
        case .drive(let drive): Launcher.open(drive.url)
        case .pullRequest(let pullRequest): Launcher.open(pullRequest.url)
        case .model(let model): return .useModel(model)
        case .hint: return .stay
        case .quicklinksError: Launcher.revealQuicklinksFile()
        }
        return .done(delivered: nil)
    }
}
