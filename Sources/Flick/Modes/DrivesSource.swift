import FlickCore

final class DrivesSource: ModeSource {
    var onUpdate: () -> Void = {}
    private var drives: [Drive] = []

    func enter() {
        drives = MountedDrives.scan()
    }

    func results(for query: String) -> [ResultItem] {
        Drives.results(for: query, in: drives)
    }

    func remove(_ kind: ResultKind) {
        guard case .drive(let drive) = kind else { return }
        MountedDrives.eject(drive) { [weak self] in
            self?.drives.removeAll { $0 == drive }
            self?.onUpdate()
        }
    }
}
