import Foundation

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSONValue].self)) }
    }

    var array: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    var string: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    subscript(index: Int) -> JSONValue? {
        guard let array, array.indices.contains(index) else { return nil }
        return array[index]
    }
}
