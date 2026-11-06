import Testing
@testable import FlickCore

struct LiveServersTests {
    let listening = """
    p606
    cControlCenter
    f10
    n*:7000
    f11
    n*:7000
    p11605
    cnode
    f13
    n*:3000
    p17732
    cadb
    f8
    n127.0.0.1:5037
    p50461
    cnode
    f14
    n[::1]:62435
    """

    let workingDirectories = """
    p606
    fcwd
    n/
    p11605
    fcwd
    n/Users/me/Developer/web
    p17732
    fcwd
    n/Users/me/Developer/app
    """

    @Test func readsOneSocketPerProcessAndPort() {
        let sockets = LiveServers.sockets(fromLsof: listening)
        #expect(sockets.map(\.port) == [7000, 3000, 5037, 62435])
        #expect(sockets.map(\.process) == ["ControlCenter", "node", "adb", "node"])
    }

    @Test func readsWorkingDirectoryPerProcess() {
        let directories = LiveServers.directories(fromLsof: workingDirectories)
        #expect(directories == [606: "/", 11605: "/Users/me/Developer/web", 17732: "/Users/me/Developer/app"])
    }

    @Test func keepsOnlyServersStartedFromAProjectSortedByPort() {
        let servers = LiveServers.servers(sockets: LiveServers.sockets(fromLsof: listening),
                                          directories: LiveServers.directories(fromLsof: workingDirectories))
        #expect(servers.map(\.port) == [3000, 5037])
        #expect(servers.map(\.name) == ["web", "app"])
    }

    @Test func serverOpensOnLocalhost() {
        let server = LiveServer(pid: 1, process: "node", port: 3000, directory: "/Users/me/web")
        #expect(server.url?.absoluteString == "http://localhost:3000")
    }
}
