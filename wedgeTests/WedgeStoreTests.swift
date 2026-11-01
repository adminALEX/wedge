import Foundation
import Testing
@testable import wedge

@Suite("WedgeStore")
@MainActor
struct WedgeStoreTests {

    @Test("first add becomes one thing")
    func firstAddBecomesOneThing() throws {
        let store = WedgeStore()
        let item = try store.add("Ship v1")
        #expect(store.items.count == 1)
        #expect(store.oneThing?.id == item.id)
        #expect(store.oneThing?.text == "Ship v1")
    }

    @Test("later adds append to bottom of up next")
    func laterAddsAppend() throws {
        let store = WedgeStore()
        _ = try store.add("One")
        _ = try store.add("Two")
        #expect(store.items.map(\.text) == ["One", "Two"])
        #expect(store.oneThing?.text == "One")
    }

    @Test("trims whitespace and rejects empty")
    func rejectsEmpty() {
        let store = WedgeStore()
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
        let store = WedgeStore()
        let item = try store.add("  Focus  ")
        #expect(item.text == "Focus")
        #expect(store.oneThing?.text == "Focus")
    }

    @Test("rejects text longer than 40 characters")
    func rejectsTooLong() {
        let store = WedgeStore()
        let text = String(repeating: "a", count: 41)
        #expect(throws: WedgeStoreError.textTooLong(max: 40)) {
            try store.add(text)
        }
    }

    @Test("accepts text with exactly 40 characters")
    func acceptsExactLimit() throws {
        let store = WedgeStore()
        let text = String(repeating: "b", count: 40)
        _ = try store.add(text)
        #expect(store.oneThing?.text == text)
    }

    @Test("completeOneThing removes top and promotes next")
    func completePromotesNext() throws {
        let store = WedgeStore()
        _ = try store.add("A")
        _ = try store.add("B")
        let done = store.completeOneThing()
        #expect(done?.text == "A")
        #expect(store.oneThing?.text == "B")
        #expect(store.items.count == 1)
    }

    @Test("completeOneThing on empty returns nil")
    func completeEmpty() {
        let store = WedgeStore()
        #expect(store.completeOneThing() == nil)
    }

    @Test("completing the last item leaves empty icon-only state")
    func completeLastItemEmpties() throws {
        let store = WedgeStore()
        _ = try store.add("Only")
        #expect(store.completeOneThing()?.text == "Only")
        #expect(store.oneThing == nil)
        #expect(store.items.isEmpty)
    }

    @Test("delete removes by id")
    func deleteById() throws {
        let store = WedgeStore()
        let a = try store.add("A")
        _ = try store.add("B")
        store.delete(id: a.id)
        #expect(store.items.map(\.text) == ["B"])
        #expect(store.oneThing?.text == "B")
    }

    @Test("delete unknown id is a no-op")
    func deleteUnknownId() throws {
        let store = WedgeStore()
        _ = try store.add("A")
        store.delete(id: UUID())
        #expect(store.items.map(\.text) == ["A"])
    }

    @Test("update enforces max length")
    func updateEnforcesLimit() throws {
        let store = WedgeStore()
        let item = try store.add("Hi")
        #expect(throws: WedgeStoreError.textTooLong(max: 40)) {
            try store.update(id: item.id, text: String(repeating: "x", count: 41))
        }
        #expect(store.oneThing?.text == "Hi")
    }

    @Test("update rejects empty after trim")
    func updateRejectsEmpty() throws {
        let store = WedgeStore()
        let item = try store.add("Keep")
        #expect(throws: WedgeStoreError.emptyText) {
            try store.update(id: item.id, text: "   ")
        }
        #expect(store.oneThing?.text == "Keep")
    }

    @Test("update trims and rewrites text")
    func updateTrims() throws {
        let store = WedgeStore()
        let item = try store.add("Old")
        try store.update(id: item.id, text: "  New  ")
        #expect(store.oneThing?.text == "New")
    }

    @Test("update unknown id is a no-op")
    func updateUnknownId() throws {
        let store = WedgeStore()
        _ = try store.add("A")
        try store.update(id: UUID(), text: "Nope")
        #expect(store.items.map(\.text) == ["A"])
    }

    @Test("move reorders items")
    func moveReorders() throws {
        let store = WedgeStore()
        _ = try store.add("A")
        _ = try store.add("B")
        _ = try store.add("C")
        store.move(from: IndexSet(integer: 2), to: 0)
        #expect(store.items.map(\.text) == ["C", "A", "B"])
        #expect(store.oneThing?.text == "C")
    }

    @Test("replaceAll swaps the list")
    func replaceAll() throws {
        let store = WedgeStore()
        _ = try store.add("Transient")
        store.replaceAll([WedgeItem(text: "Loaded")])
        #expect(store.items.map(\.text) == ["Loaded"])
        #expect(store.oneThing?.text == "Loaded")
    }
}
