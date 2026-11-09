import Testing
@testable import FlickCore

struct RelocationStrategyTests {
    @Test func mergesIntoAFolderAnotherMacAlreadySynced() {
        #expect(RelocationStrategy.moving(toExisting: true, targetIsLocal: false) == .merge)
    }

    @Test func writesIntoAnEmptySyncFolder() {
        #expect(RelocationStrategy.moving(toExisting: false, targetIsLocal: false) == .overwrite)
    }

    @Test func overwritesStaleLocalFilesWhenSyncIsTurnedOff() {
        #expect(RelocationStrategy.moving(toExisting: true, targetIsLocal: true) == .overwrite)
    }
}
