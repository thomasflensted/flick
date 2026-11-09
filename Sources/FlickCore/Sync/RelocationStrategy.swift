public enum RelocationStrategy: Equatable {
    case overwrite
    case merge

    public static func moving(toExisting targetExists: Bool, targetIsLocal: Bool) -> RelocationStrategy {
        targetExists && !targetIsLocal ? .merge : .overwrite
    }
}
