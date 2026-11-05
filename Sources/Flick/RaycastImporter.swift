import Foundation

/// Reads quicklinks out of a Raycast "Export Settings & Data" file (.rayconfig).
/// The export is AES-256-CBC encrypted (no salt) with the password chosen at export,
/// followed by a 16-byte header and gzipped JSON. Plain JSON files also work.
enum RaycastImporter {
    enum ImportError: LocalizedError {
        case needsPassword, wrongPasswordOrFormat, noQuicklinks
        var errorDescription: String? {
            switch self {
            case .needsPassword: return "This export is password protected."
            case .wrongPasswordOrFormat: return "Couldn't decrypt the file. Check the password you set when exporting from Raycast."
            case .noQuicklinks: return "The file was read, but it contains no quicklinks."
            }
        }
    }

    static func load(url: URL, password: String?) throws -> [Quicklink] {
        let raw = try Data(contentsOf: url)
        var candidates = [raw]
        if let g = gunzip(raw) { candidates.append(g) }

        if let pw = password, !pw.isEmpty {
            for md in ["sha256", "md5"] {
                guard let dec = run("/usr/bin/openssl",
                                    ["enc", "-d", "-aes-256-cbc", "-nosalt", "-md", md, "-in", url.path, "-pass", "env:FLICK_PW"],
                                    env: ["FLICK_PW": pw]) else { continue }
                candidates.append(dec)
                if let g = gunzip(dec) { candidates.append(g) }
                if dec.count > 16 {
                    let body = Data(dec.dropFirst(16))
                    candidates.append(body)
                    if let g = gunzip(body) { candidates.append(g) }
                }
            }
        }

        var parsedAny = false
        for c in candidates {
            guard let obj = try? JSONSerialization.jsonObject(with: c) else { continue }
            parsedAny = true
            let links = extract(obj)
            if !links.isEmpty { return links }
        }
        if parsedAny { throw ImportError.noQuicklinks }
        throw (password?.isEmpty ?? true) ? ImportError.needsPassword : ImportError.wrongPasswordOrFormat
    }

    /// Finds every object with string "name" + "link" anywhere in the JSON tree.
    static func extract(_ obj: Any) -> [Quicklink] {
        var out: [Quicklink] = []
        func walk(_ o: Any) {
            if let d = o as? [String: Any] {
                // Raycast exports quicklinks as {name, url, uuid, ...}; older/other formats use "link".
                if let name = d["name"] as? String,
                   let link = (d["link"] as? String) ?? (d["uuid"] != nil ? d["url"] as? String : nil) {
                    let app = appIdentifier(d["openWith"] ?? d["application"] ?? d["app"])
                    let kw = (d["alias"] as? String) ?? (d["keyword"] as? String)
                    var ql = Quicklink(name: name, link: link, openWith: app,
                                       keyword: (kw?.isEmpty ?? true) ? nil : kw)
                    if let u = (d["uuid"] as? String).flatMap(UUID.init(uuidString:)) { ql.id = u }
                    out.append(ql)
                    return
                }
                d.values.forEach(walk)
            } else if let a = o as? [Any] {
                a.forEach(walk)
            }
        }
        // A full Raycast export holds many packages; only look at the quicklinks one if present.
        if let root = obj as? [String: Any], let pkg = root["builtin_package_quicklinks"] {
            walk(pkg)
        } else {
            walk(obj)
        }
        return out
    }

    private static func appIdentifier(_ v: Any?) -> String? {
        if let s = v as? String, !s.isEmpty { return s }
        if let d = v as? [String: Any] {
            for k in ["bundleId", "bundleIdentifier", "path"] {
                if let s = d[k] as? String, !s.isEmpty { return s }
            }
        }
        return nil
    }

    private static func gunzip(_ data: Data) -> Data? {
        guard data.count > 2, data[data.startIndex] == 0x1f, data[data.startIndex + 1] == 0x8b else { return nil }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".gz")
        defer { try? FileManager.default.removeItem(at: tmp) }
        guard (try? data.write(to: tmp)) != nil else { return nil }
        return run("/usr/bin/gunzip", ["-c", tmp.path])
    }

    private static func run(_ tool: String, _ args: [String], env: [String: String] = [:]) -> Data? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: tool)
        p.arguments = args
        p.environment = ProcessInfo.processInfo.environment.merging(env) { $1 }
        let out = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return p.terminationStatus == 0 && !data.isEmpty ? data : nil
    }
}
