import FlickCore
import Foundation

enum AppIndex {
    private static let roots = [
        "/Applications", "/Applications/Utilities", "/System/Applications",
        "/System/Applications/Utilities", NSHomeDirectory() + "/Applications",
    ]
    private static let finder = "/System/Library/CoreServices/Finder.app"

    static func scan() -> [AppEntry] {
        let paths = roots.flatMap(appPaths(in:)) + [finder]
        var seen = Set<String>()
        return paths.filter { seen.insert($0).inserted }.map(entry(for:))
    }

    private static func appPaths(in root: String) -> [String] {
        children(of: root).flatMap { path in
            path.hasSuffix(".app") ? [path] : children(of: path).filter { $0.hasSuffix(".app") }
        }
    }

    private static func children(of dir: String) -> [String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? []
        return names.filter { !$0.hasPrefix(".") }.map { "\(dir)/\($0)" }
    }

    private static func entry(for path: String) -> AppEntry {
        let name = FileManager.default.displayName(atPath: path)
        return AppEntry(name: name.hasSuffix(".app") ? String(name.dropLast(4)) : name, path: path)
    }
}
