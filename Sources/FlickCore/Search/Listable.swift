import Foundation

public protocol Listable: Codable, Identifiable where ID == UUID {
    func isDuplicate(of other: Self) -> Bool
}
