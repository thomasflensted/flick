import Foundation

enum Background {
    static func load<Value>(_ work: @escaping () -> Value, then done: @escaping (Value) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let value = work()
            DispatchQueue.main.async { done(value) }
        }
    }
}
