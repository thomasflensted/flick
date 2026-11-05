public enum SnippetTemplate {
    public static let idPlaceholder = "{id}"
    static let raycastUUIDPlaceholder = "{uuid}"

    public static func expand(_ text: String, id: () -> String) -> String {
        let parts = text.components(separatedBy: idPlaceholder)
        return parts.dropFirst().reduce(parts[0]) { $0 + id() + $1 }
    }

    public static func fromRaycast(_ text: String) -> String {
        text.replacingOccurrences(of: raycastUUIDPlaceholder, with: idPlaceholder)
    }
}
