final class UsageStore {
    private let file = JSONFile<[String: Int]>(url: AppSupport.usageFile)
    private(set) var counts: [String: Int]

    init() {
        counts = (try? file.load()) ?? [:]
    }

    func record(_ key: String) {
        counts[key, default: 0] += 1
        file.save(counts)
    }
}
