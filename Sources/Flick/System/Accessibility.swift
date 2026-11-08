import ApplicationServices

enum Accessibility {
    // The options dictionary is built with CFDictionaryCreate to avoid a bridging cast.
    static func isTrusted() -> Bool {
        guard let yes = kCFBooleanTrue else { return AXIsProcessTrusted() }
        var keys: [UnsafeRawPointer?] = [UnsafeRawPointer(Unmanaged.passUnretained(kAXTrustedCheckOptionPrompt.takeUnretainedValue()).toOpaque())]
        var values: [UnsafeRawPointer?] = [UnsafeRawPointer(Unmanaged.passUnretained(yes).toOpaque())]
        let options = CFDictionaryCreate(nil, &keys, &values, 1, nil, nil)
        return AXIsProcessTrustedWithOptions(options)
    }
}
