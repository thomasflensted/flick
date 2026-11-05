public enum Direction {
    case up, down, left, right
}

public enum Selection {
    public static func next(from index: Int, _ direction: Direction, count: Int, columns: Int?) -> Int {
        guard count > 0 else { return 0 }
        guard let columns else { return inList(from: index, direction, count: count) }
        return inGrid(from: index, direction, count: count, columns: columns)
    }

    private static func inList(from index: Int, _ direction: Direction, count: Int) -> Int {
        switch direction {
        case .up: return (index - 1 + count) % count
        case .down: return (index + 1) % count
        case .left, .right: return index
        }
    }

    private static func inGrid(from index: Int, _ direction: Direction, count: Int, columns: Int) -> Int {
        let target: Int
        switch direction {
        case .left: target = index - 1
        case .right: target = index + 1
        case .up: target = index - columns
        case .down: target = index + columns
        }
        return (0..<count).contains(target) ? target : index
    }
}
