public enum LiveServers {
    public struct Socket: Equatable {
        public let pid: Int32
        public let process: String
        public let port: Int
    }

    private struct Entry {
        let pid: Int32
        let process: String
        let name: String
    }

    public static func sockets(fromLsof output: String) -> [Socket] {
        var sockets: [Socket] = []
        for entry in entries(in: output) {
            guard let port = port(in: entry.name) else { continue }
            let socket = Socket(pid: entry.pid, process: entry.process, port: port)
            if !sockets.contains(socket) { sockets.append(socket) }
        }
        return sockets
    }

    public static func directories(fromLsof output: String) -> [Int32: String] {
        Dictionary(entries(in: output).map { ($0.pid, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    public static func servers(sockets: [Socket], directories: [Int32: String]) -> [LiveServer] {
        sockets.compactMap { socket in
            guard let directory = directories[socket.pid], isStartedFromProject(directory) else { return nil }
            return LiveServer(pid: socket.pid, process: socket.process, port: socket.port, directory: directory)
        }
        .sorted { $0.port < $1.port }
    }

    public static func results(for query: String, in servers: [LiveServer]) -> [ResultItem] {
        if servers.isEmpty { return [.hint("No live servers found")] }
        return Ranker(usage: [:])
            .rank(servers, query: query, texts: { [$0.name, $0.process, String($0.port)] }, key: ResultItem.serverID)
            .map(ResultItem.server)
    }

    static func isStartedFromProject(_ directory: String) -> Bool {
        directory != "/"
    }

    static func port(in address: String) -> Int? {
        address.split(separator: ":").last.flatMap { Int($0) }
    }

    private static func entries(in output: String) -> [Entry] {
        var pid: Int32?
        var process = ""
        var entries: [Entry] = []
        for line in output.split(whereSeparator: \.isNewline) {
            let value = String(line.dropFirst())
            switch line.first {
            case "p": pid = Int32(value)
            case "c": process = value
            case "n": if let pid { entries.append(Entry(pid: pid, process: process, name: value)) }
            default: break
            }
        }
        return entries
    }
}
