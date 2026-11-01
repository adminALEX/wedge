import Foundation
import Testing

@testable import wedge

@Suite("WedgeStore undo")
@MainActor
struct WedgeStoreUndoTests {

    @Test func undoRestoresToTop() throws {
        let s = store(["A", "B"])
        s.completeNow()
        #expect(s.canUndoDone)
        #expect(s.undoDone())
        #expect(s.items.map(\.text) == ["A", "B"])
        #expect(!s.canUndoDone)
    }

    @Test func undoWithNothingToUndoReturnsFalse() {
        let s = store(["A"])
        #expect(!s.canUndoDone)
        #expect(!s.undoDone())
        #expect(s.items.map(\.text) == ["A"])
    }

    @Test func undoPersists() {
        let p = InMemoryWedgePersistence(items: [WedgeItem(text: "A"), WedgeItem(text: "B")])
        let s = WedgeStore(persister: p)
        s.completeNow()
        s.undoDone()
        #expect(p.items.map(\.text) == ["A", "B"])
    }

    @Test func undoClearedByAnyOtherMutation() throws {
        let mutations: [(name: String, apply: (WedgeStore) throws -> Void)] = [
            ("add", { try $0.add("D") }),
            ("update", { try $0.update(id: $0.items[0].id, text: "Z") }),
            ("delete", { $0.delete(id: $0.items[0].id) }),
            ("moveOffsets", { $0.move(fromOffsets: IndexSet(integer: 0), toOffset: 2) }),
            ("moveBy", { $0.move(id: $0.items[0].id, by: 1) }),
        ]
        for mutation in mutations {
            let s = store(["A", "B", "C"])
            s.completeNow()
            #expect(s.canUndoDone, "\(mutation.name): precondition")
            try mutation.apply(s)
            #expect(!s.canUndoDone, "\(mutation.name) should clear undo")
        }
    }

    @Test func rejectedEditKeepsUndo() throws {
        let s = store(["A", "B"])
        s.completeNow()
        #expect(throws: WedgeStoreError.emptyText) { try s.add("  ") }
        #expect(s.canUndoDone)
    }

    @Test func secondDoneReplacesUndo() throws {
        let s = store(["A", "B", "C"])
        s.completeNow()
        s.completeNow()
        #expect(s.undoDone())
        #expect(s.items.map(\.text) == ["B", "C"])
    }
}
