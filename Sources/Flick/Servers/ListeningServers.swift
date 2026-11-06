import FlickCore
import Foundation

enum ListeningServers {
    static func scan() -> [LiveServer] {
        let sockets = LiveServers.sockets(fromLsof: lsof(["-iTCP", "-sTCP:LISTEN"]))
        guard !sockets.isEmpty else { return [] }
        let pids = Set(sockets.map(\.pid)).map(String.init).joined(separator: ",")
        let directories = LiveServers.directories(fromLsof: lsof(["-a", "-d", "cwd", "-p", pids]))
        return LiveServers.servers(sockets: sockets, directories: directories)
    }

    static func stop(_ server: LiveServer) {
        kill(server.pid, SIGTERM)
    }

    private static func lsof(_ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-nP", "-Fpcn"] + arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return "" }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }
}
