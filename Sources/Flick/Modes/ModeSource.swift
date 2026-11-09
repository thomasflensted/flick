import FlickCore

protocol ModeSource: AnyObject {
    var onUpdate: () -> Void { get set }
    var isLoading: Bool { get }
    func enter()
    func queryChanged(_ query: String)
    func results(for query: String) -> [ResultItem]
    func remove(_ kind: ResultKind)
}

extension ModeSource {
    var isLoading: Bool { false }
    func enter() {}
    func queryChanged(_ query: String) {}
    func remove(_ kind: ResultKind) {}
}
