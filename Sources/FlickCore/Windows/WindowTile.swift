import CoreGraphics

public enum WindowTile: CaseIterable, Hashable {
    case fullScreen
    case leftHalf
    case rightHalf

    public var id: String {
        switch self {
        case .fullScreen: return "fullScreen"
        case .leftHalf: return "leftHalf"
        case .rightHalf: return "rightHalf"
        }
    }

    public var title: String {
        switch self {
        case .fullScreen: return "Full Screen"
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        }
    }

    public var aliases: [String] {
        switch self {
        case .fullScreen: return ["Maximize Window", "Window Full Screen"]
        case .leftHalf: return ["Window Left Half"]
        case .rightHalf: return ["Window Right Half"]
        }
    }

    public var subtitle: String {
        switch self {
        case .fullScreen: return "Make the front window fill the screen"
        case .leftHalf: return "Move the front window to the left half"
        case .rightHalf: return "Move the front window to the right half"
        }
    }

    public var symbol: String {
        switch self {
        case .fullScreen: return "rectangle.inset.filled"
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        }
    }

    public func frame(in screen: CGRect) -> CGRect {
        let half = CGSize(width: screen.width / 2, height: screen.height)
        switch self {
        case .fullScreen: return screen
        case .leftHalf: return CGRect(origin: screen.origin, size: half)
        case .rightHalf: return CGRect(origin: CGPoint(x: screen.midX, y: screen.minY), size: half)
        }
    }

    public static func topLeftOrigin(of frame: CGRect, primaryScreenHeight: CGFloat) -> CGPoint {
        CGPoint(x: frame.minX, y: primaryScreenHeight - frame.maxY)
    }
}
