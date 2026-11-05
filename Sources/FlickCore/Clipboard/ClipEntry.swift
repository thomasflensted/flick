import Foundation

public struct ClipEntry: Codable, Hashable, Identifiable {
    public let id: UUID
    public let text: String
    public let copiedAt: Date
    public let appName: String?
    public let appPath: String?

    public init(id: UUID = UUID(), text: String, copiedAt: Date, appName: String? = nil, appPath: String? = nil) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
        self.appName = appName
        self.appPath = appPath
    }
}
