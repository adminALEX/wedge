import Foundation
import Testing
@testable import wedge

@Suite("WedgeStore")
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

    @Test("delete removes by id")
    func deleteById() throws {
        let store = WedgeStore()
        let a = try store.add("A")
        _ = try store.add("B")
        store.delete(id: a.id)
        #expect(store.items.map(\.text) == ["B"])
    }

    @Test("update enforces max length")
    func updateEnforcesLimit() throws {
        let store = WedgeStore()
        let item = try store.add("Hi")
        #expect(throws: WedgeStoreError.textTooLong(max: 40)) {
            try store.update(id: item.id, text: String(repeating: "x", count: 41))
        }
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
}
