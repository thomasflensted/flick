import Foundation

public enum ChatExpiry {
    static let idleLimit: TimeInterval = 30 * 60

    public static func isExpired(lastActivity: Date?, now: Date) -> Bool {
        guard let lastActivity else { return false }
        return now.timeIntervalSince(lastActivity) > idleLimit
    }
}
