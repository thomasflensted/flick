public enum NanoID {
    static let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_-")
    public static let defaultLength = 8

    public static func make<G: RandomNumberGenerator>(length: Int = defaultLength, using generator: inout G) -> String {
        String((0..<length).map { _ in alphabet.randomElement(using: &generator)! })
    }

    public static func make() -> String {
        var generator = SystemRandomNumberGenerator()
        return make(using: &generator)
    }
}
