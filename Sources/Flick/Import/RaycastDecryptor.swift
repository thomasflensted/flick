import Foundation

enum RaycastDecryptor {
    struct WrongPassword: LocalizedError {
        var errorDescription: String? { "Couldn't decrypt the file. Check the password you set when exporting from Raycast." }
    }

    // Raycast exports are AES-256-CBC without salt, then a 16-byte header, then gzipped JSON.
    private static let script = #"openssl enc -d -aes-256-cbc -nosalt -md sha256 -in "$FLICK_FILE" -pass env:FLICK_PW | tail -c +17 | gunzip -c"#

    static func decrypt(_ file: URL, password: String) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-o", "pipefail", "-c", script]
        process.environment = ["PATH": "/usr/bin:/bin", "FLICK_FILE": file.path, "FLICK_PW": password]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0, !data.isEmpty else { throw WrongPassword() }
        return data
    }
}
