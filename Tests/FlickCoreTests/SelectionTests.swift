import Testing
@testable import FlickCore

struct SelectionTests {
    @Test func listWrapsAround() {
        #expect(Selection.next(from: 0, .up, count: 5, columns: nil) == 4)
        #expect(Selection.next(from: 4, .down, count: 5, columns: nil) == 0)
    }

    @Test func listIgnoresLeftAndRight() {
        #expect(Selection.next(from: 2, .left, count: 5, columns: nil) == 2)
    }

    @Test func gridMovesByRow() {
        #expect(Selection.next(from: 2, .down, count: 30, columns: 9) == 11)
        #expect(Selection.next(from: 11, .up, count: 30, columns: 9) == 2)
    }

    @Test func gridMovesAcrossRowEnds() {
        #expect(Selection.next(from: 8, .right, count: 30, columns: 9) == 9)
        #expect(Selection.next(from: 9, .left, count: 30, columns: 9) == 8)
    }

    @Test func gridStaysPutAtEdges() {
        #expect(Selection.next(from: 3, .up, count: 30, columns: 9) == 3)
        #expect(Selection.next(from: 25, .down, count: 30, columns: 9) == 25)
        #expect(Selection.next(from: 0, .left, count: 30, columns: 9) == 0)
    }

    @Test func emptyResultsSelectNothing() {
        #expect(Selection.next(from: 0, .down, count: 0, columns: 9) == 0)
    }
}
