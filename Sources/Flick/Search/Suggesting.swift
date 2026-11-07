protocol Suggesting: AnyObject {
    var onUpdate: () -> Void { get set }
    var suggestions: [String] { get }
    func suggest(_ query: String)
    func clear()
}
