import Foundation
import Testing
@testable import wedge

@Suite("WedgeStore persistence and issues")
@MainActor
struct WedgeStoreIssueTests {

    @Test func persistsAfterEveryMutation() throws {
        let p = InMemoryWedgePersistence()
        let s = WedgeStore(persister: p)
        let a = try s.add("A")
        try s.add("B")
        #expect(p.items.map(\.text) == ["A", "B"])
        try s.update(id: a.id, text: "A2")
        #expect(p.items.first?.text == "A2")
        s.move(id: a.id, by: 1)
        #expect(p.items.map(\.text) == ["B", "A2"])
        s.move(fromOffsets: IndexSet(integer: 1), toOffset: 0)
        #expect(p.items.map(\.text) == ["A2", "B"])
        s.delete(id: a.id)
        #expect(p.items.map(\.text) == ["B"])
        s.completeNow()
        #expect(p.items.isEmpty)
    }

    @Test func saveFailureSetsIssueAndClearsOnSuccess() throws {
        let p = InMemoryWedgePersistence()
        p.failSaves = true
        let s = WedgeStore(persister: p)
        try s.add("A")
        #expect(s.issue == .saveFailed)
        p.failSaves = false
        try s.add("B")
        #expect(s.issue == nil)
    }

    @Test func loadsExistingItems() {
        let s = store(["A", "B", "C"])
        #expect(s.now?.text == "A")
        #expect(s.upNext.map(\.text) == ["B", "C"])
        #expect(s.issue == nil)
    }

    @Test func corruptLoadStartsEmptyWithIssue() {
        let backup = URL(fileURLWithPath: "/tmp/wedge.corrupt-20260101-000000.json")
        let s = WedgeStore(persister: FailingLoadPersistence(error: WedgePersistenceError.corrupt(backup: backup)))
        #expect(s.items.isEmpty)
        #expect(s.issue == .recoveredFromCorruptFile)
    }

    @Test func successfulSaveClearsRecoveredIssue() throws {
        let backup = URL(fileURLWithPath: "/tmp/wedge.corrupt-20260101-000000.json")
        let s = WedgeStore(persister: FailingLoadPersistence(error: WedgePersistenceError.corrupt(backup: backup)))
        #expect(s.issue == .recoveredFromCorruptFile)
        try s.add("A")
        #expect(s.issue == nil)
    }

    @Test func unsupportedVersionDisablesSaving() throws {
        let p = FailingLoadPersistence(error: WedgePersistenceError.unsupportedVersion(2))
        let s = WedgeStore(persister: p)
        #expect(s.items.isEmpty)
        #expect(s.issue == .loadFailed)
        try s.add("A")
        #expect(s.items.map(\.text) == ["A"])
        #expect(s.issue == .loadFailed)
        s.completeNow()
        s.delete(id: UUID())
        #expect(s.issue == .loadFailed)
        #expect(p.saveCount == 0)
    }

    @Test func genericLoadErrorDisablesSaving() throws {
        let p = FailingLoadPersistence(error: CocoaError(.fileReadNoPermission))
        let s = WedgeStore(persister: p)
        #expect(s.issue == .loadFailed)
        try s.add("A")
        try s.add("B")
        #expect(s.issue == .loadFailed)
        #expect(p.saveCount == 0)
    }
}
