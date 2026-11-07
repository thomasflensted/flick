import Foundation
import Testing
@testable import FlickCore

struct DrivesTests {
    private let usb = Drive(name: "Backup", url: URL(fileURLWithPath: "/Volumes/Backup"), capacity: 64_000_000_000)
    private let image = Drive(name: "FlickTest", url: URL(fileURLWithPath: "/Volumes/FlickTest"), capacity: nil)

    @Test func ejectsExternalDrivesDiskImagesAndNetworkShares() {
        #expect(Drive.canEject(isRoot: false, isEjectable: true, isRemovable: true, isLocal: true))
        #expect(Drive.canEject(isRoot: false, isEjectable: false, isRemovable: false, isLocal: false))
    }

    @Test func leavesTheSystemDiskAndInternalPartitionsAlone() {
        #expect(!Drive.canEject(isRoot: true, isEjectable: false, isRemovable: false, isLocal: true))
        #expect(!Drive.canEject(isRoot: false, isEjectable: false, isRemovable: false, isLocal: true))
    }

    @Test func showsPathAndSize() {
        #expect(usb.details == "/Volumes/Backup · 64 GB")
        #expect(image.details == "/Volumes/FlickTest")
    }

    @Test func filtersByName() {
        #expect(Drives.results(for: "back", in: [usb, image]).map(\.title) == ["Backup"])
    }

    @Test func saysSoWhenNothingCanBeEjected() {
        #expect(Drives.results(for: "", in: []) == [.hint("No drives to eject")])
    }

    @Test func eachModeNamesItsEnterAction() {
        #expect(Mode.drives.enterLabel == "Eject")
        #expect(Mode.servers.enterLabel == nil)
    }
}
