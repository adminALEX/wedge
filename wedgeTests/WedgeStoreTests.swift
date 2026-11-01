import Foundation
import Testing

@testable import wedge

@Suite("WedgeStore")
@MainActor
struct WedgeStoreTests {

    @Test("first add becomes Now")
    func firstAddBecomesNow() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        let item = try store.add("Ship v1")
        #expect(store.items.count == 1)
        #expect(store.now?.id == item.id)
        #expect(store.now?.text == "Ship v1")
    }

    @Test("later adds append to bottom of up next")
    func laterAddsAppend() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        _ = try store.add("One")
        _ = try store.add("Two")
        #expect(store.items.map(\.text) == ["One", "Two"])
        #expect(store.now?.text == "One")
    }

    @Test("trims whitespace and rejects empty")
    func rejectsEmpty() {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        #expect(throws: WedgeStoreError.emptyText) {
            try store.add("   ")
        }
        #expect(throws: WedgeStoreError.emptyText) {
            try store.add("")
        }
        #expect(throws: WedgeStoreError.emptyText) {
            try store.add("\n\t")
        }
    }

    @Test("add trims surrounding whitespace")
    func addTrimsWhitespace() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        let item = try store.add("  Focus  ")
        #expect(item.text == "Focus")
        #expect(store.now?.text == "Focus")
    }

    @Test("rejects text longer than 40 characters")
    func rejectsTooLong() {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        let text = String(repeating: "a", count: 41)
        #expect(throws: WedgeStoreError.textTooLong(max: 40)) {
            try store.add(text)
        }
    }

    @Test("accepts text with exactly 40 characters")
    func acceptsExactLimit() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        let text = String(repeating: "b", count: 40)
        _ = try store.add(text)
        #expect(store.now?.text == text)
    }

    @Test("completeNow removes top and promotes next")
    func completePromotesNext() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        _ = try store.add("A")
        _ = try store.add("B")
        let done = store.completeNow()
        #expect(done?.text == "A")
        #expect(store.now?.text == "B")
        #expect(store.items.count == 1)
    }

    @Test("completeNow on empty returns nil")
    func completeEmpty() {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        #expect(store.completeNow() == nil)
    }

    @Test("completing the last item leaves empty icon-only state")
    func completeLastItemEmpties() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        _ = try store.add("Only")
        #expect(store.completeNow()?.text == "Only")
        #expect(store.now == nil)
        #expect(store.items.isEmpty)
    }

    @Test("delete removes by id")
    func deleteById() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        let a = try store.add("A")
        _ = try store.add("B")
        store.delete(id: a.id)
        #expect(store.items.map(\.text) == ["B"])
        #expect(store.now?.text == "B")
    }

    @Test("delete unknown id is a no-op")
    func deleteUnknownId() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        _ = try store.add("A")
        store.delete(id: UUID())
        #expect(store.items.map(\.text) == ["A"])
    }

    @Test("update enforces max length")
    func updateEnforcesLimit() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        let item = try store.add("Hi")
        #expect(throws: WedgeStoreError.textTooLong(max: 40)) {
            try store.update(id: item.id, text: String(repeating: "x", count: 41))
        }
        #expect(store.now?.text == "Hi")
    }

    @Test("update rejects empty after trim")
    func updateRejectsEmpty() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        let item = try store.add("Keep")
        #expect(throws: WedgeStoreError.emptyText) {
            try store.update(id: item.id, text: "   ")
        }
        #expect(store.now?.text == "Keep")
    }

    @Test("update trims and rewrites text")
    func updateTrims() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        let item = try store.add("Old")
        try store.update(id: item.id, text: "  New  ")
        #expect(store.now?.text == "New")
    }

    @Test("update unknown id is a no-op")
    func updateUnknownId() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        _ = try store.add("A")
        try store.update(id: UUID(), text: "Nope")
        #expect(store.items.map(\.text) == ["A"])
    }

    @Test("move reorders items")
    func moveReorders() throws {
        let store = WedgeStore(persister: InMemoryWedgePersistence())
        _ = try store.add("A")
        _ = try store.add("B")
        _ = try store.add("C")
        store.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        #expect(store.items.map(\.text) == ["C", "A", "B"])
        #expect(store.now?.text == "C")
    }

    @Test func collapsesNewlinesAndTabs() throws {
        #expect(try WedgeStore.normalized("Line one\n\tLine two") == "Line one Line two")
    }

    @Test func acceptsFortyGraphemeClusters() throws {
        let family = "👨‍👩‍👧‍👦"
        let s = String(repeating: family, count: 40)
        #expect(try WedgeStore.normalized(s) == s)
        #expect(throws: WedgeStoreError.textTooLong(max: 40)) {
            try WedgeStore.normalized(s + family)
        }
    }

    @Test func moveByClampsAtEdges() throws {
        let s = store(["A", "B"])
        s.move(id: s.items[0].id, by: -1)
        #expect(s.items.map(\.text) == ["A", "B"])
        s.move(id: s.items[1].id, by: 1)
        #expect(s.items.map(\.text) == ["A", "B"])
        s.move(id: s.items[0].id, by: 5)
        #expect(s.items.map(\.text) == ["B", "A"])
    }
}
