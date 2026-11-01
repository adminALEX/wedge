import Foundation
import Testing
@testable import wedge

@Suite("PanelRows")
@MainActor
struct PanelRowsTests {
    private let items = ["Now", "A", "B", "C"].map { WedgeItem(text: $0) }

    @Test func rowsPutLabelAfterNow() {
        let rows = PanelRows.rows(for: items)
        #expect(rows.count == 5)
        #expect(rows[0] == .item(items[0], position: 1))
        #expect(rows[1] == .upNextLabel)
        #expect(rows[2] == .item(items[1], position: 2))
        #expect(rows[4] == .item(items[3], position: 4))
    }

    @Test func noLabelWithoutUpNext() {
        #expect(PanelRows.rows(for: [items[0]]) == [.item(items[0], position: 1)])
        #expect(PanelRows.rows(for: []).isEmpty)
    }

    @Test func dragToTopMakesRowNow() {
        let move = PanelRows.storeMove(from: [3], to: 0)  // display 3 = "B"
        #expect(move.offsets == [2])
        #expect(move.destination == 0)
        let s = store(items.map(\.text))
        s.move(fromOffsets: move.offsets, toOffset: move.destination)
        #expect(s.now?.text == "B")
    }

    @Test func destinationsAroundLabelMapToFirstUpNextSlot() {
        #expect(PanelRows.storeMove(from: [4], to: 1).destination == 1)
        #expect(PanelRows.storeMove(from: [4], to: 2).destination == 1)
        #expect(PanelRows.storeMove(from: [2], to: 4).destination == 3)
    }

    @Test func nowDraggedToEnd() {
        let move = PanelRows.storeMove(from: [0], to: 5)
        #expect(move.offsets == [0])
        #expect(move.destination == 4)
        let s = store(items.map(\.text))
        s.move(fromOffsets: move.offsets, toOffset: move.destination)
        #expect(s.items.map(\.text) == ["A", "B", "C", "Now"])
    }

    @Test func labelIsNeverASource() {
        #expect(PanelRows.storeMove(from: [1], to: 0).offsets.isEmpty)
    }
}
