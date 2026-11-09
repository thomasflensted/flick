import FlickCore

final class ServersSource: ModeSource {
    var onUpdate: () -> Void = {}
    private var servers: [LiveServer] = []

    func enter() {
        Background.load(ListeningServers.scan) { [weak self] in
            self?.servers = $0
            self?.onUpdate()
        }
    }

    func results(for query: String) -> [ResultItem] {
        LiveServers.results(for: query, in: servers)
    }

    func remove(_ kind: ResultKind) {
        guard case .server(let server) = kind else { return }
        ListeningServers.stop(server)
        servers.removeAll { $0 == server }
        onUpdate()
    }
}
