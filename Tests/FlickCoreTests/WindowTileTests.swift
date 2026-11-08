import CoreGraphics
import Testing
@testable import FlickCore

struct WindowTileTests {
    let screen = CGRect(x: 100, y: 0, width: 1600, height: 1000)

    @Test func fullScreenFillsTheScreen() {
        #expect(WindowTile.fullScreen.frame(in: screen) == screen)
    }

    @Test func halvesSplitTheScreenDownTheMiddle() {
        #expect(WindowTile.leftHalf.frame(in: screen) == CGRect(x: 100, y: 0, width: 800, height: 1000))
        #expect(WindowTile.rightHalf.frame(in: screen) == CGRect(x: 900, y: 0, width: 800, height: 1000))
    }

    @Test func originIsMeasuredFromTheTopOfThePrimaryScreen() {
        let frame = CGRect(x: 0, y: 25, width: 800, height: 950)
        #expect(WindowTile.topLeftOrigin(of: frame, primaryScreenHeight: 1000) == CGPoint(x: 0, y: 25))
        let lower = CGRect(x: 0, y: -900, width: 800, height: 900)
        #expect(WindowTile.topLeftOrigin(of: lower, primaryScreenHeight: 1000) == CGPoint(x: 0, y: 1000))
    }
}
