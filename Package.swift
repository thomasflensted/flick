// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Flick",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Flick", path: "Sources/Flick")
    ]
)
