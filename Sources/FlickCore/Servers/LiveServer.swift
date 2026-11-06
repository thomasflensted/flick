import Foundation

public struct LiveServer: Hashable {
    public let pid: Int32
    public let process: String
    public let port: Int
    public let directory: String

    public init(pid: Int32, process: String, port: Int, directory: String) {
        self.pid = pid
        self.process = process
        self.port = port
        self.directory = directory
    }

    public var name: String { URL(fileURLWithPath: directory).lastPathComponent }

    public var address: String { "localhost:\(port)" }

    public var url: URL? { URL(string: "http://\(address)") }
}
