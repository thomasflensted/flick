import Foundation

public protocol Listable: Codable, Identifiable where ID == UUID {
    func isDuplicate(of other: Self) -> Bool
}

extension Array where Element: Listable {
    @discardableResult
    public mutating func upsert(_ item: Element) -> Bool {
        guard let i = firstIndex(where: { $0.id == item.id }) else { append(item); return false }
        self[i] = item
        return true
    }

    public mutating func remove(id: UUID) -> Element? {
        firstIndex { $0.id == id }.map { remove(at: $0) }
    }
}
