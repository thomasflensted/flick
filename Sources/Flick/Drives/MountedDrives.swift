import AppKit
import FlickCore

enum MountedDrives {
    private static let keys: Set<URLResourceKey> = [.volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsRootFileSystemKey,
                                                    .volumeIsEjectableKey, .volumeIsRemovableKey, .volumeIsLocalKey]

    static func scan() -> [Drive] {
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: Array(keys), options: [.skipHiddenVolumes]) ?? []
        return urls.compactMap(drive)
    }

    static func eject(_ drive: Drive, onEjected: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let ejected = (try? NSWorkspace.shared.unmountAndEjectDevice(at: drive.url)) != nil
            DispatchQueue.main.async {
                Toast.shared.show(ejected ? .ejected(drive) : .ejectFailed(drive))
                if ejected { onEjected() }
            }
        }
    }

    private static func drive(at url: URL) -> Drive? {
        guard let values = try? url.resourceValues(forKeys: keys),
              Drive.canEject(isRoot: values.volumeIsRootFileSystem ?? false, isEjectable: values.volumeIsEjectable ?? false,
                             isRemovable: values.volumeIsRemovable ?? false, isLocal: values.volumeIsLocal ?? true)
        else { return nil }
        let capacity = values.volumeTotalCapacity.map(Int64.init)
        return Drive(name: values.volumeLocalizedName ?? url.lastPathComponent, url: url, capacity: capacity)
    }
}
