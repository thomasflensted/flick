public struct ToolCallDelta: Decodable, Equatable {
    public struct Function: Decodable, Equatable {
        let name: String?
        let arguments: String?
    }

    let index: Int
    let id: String?
    let function: Function?

    init(index: Int, id: String? = nil, name: String? = nil, arguments: String? = nil) {
        self.index = index
        self.id = id
        function = Function(name: name, arguments: arguments)
    }
}

public struct ToolCallAssembler {
    private struct Partial {
        var id = ""
        var name = ""
        var arguments = ""
    }

    private var partials: [Int: Partial] = [:]

    public init() {}

    public mutating func add(_ delta: ToolCallDelta) {
        var partial = partials[delta.index] ?? Partial()
        if let id = delta.id { partial.id = id }
        if let name = delta.function?.name { partial.name += name }
        partial.arguments += delta.function?.arguments ?? ""
        partials[delta.index] = partial
    }

    public var calls: [ToolCall] {
        partials.keys.sorted().compactMap { index in
            partials[index].map { ToolCall(id: $0.id, name: $0.name, arguments: $0.arguments.isEmpty ? "{}" : $0.arguments) }
        }
    }
}
