import Foundation
import Testing
@testable import wedge

private final class MemoryPersistence: WedgePersisting, @unchecked Sendable {
    var items: [WedgeItem] = []
    func load() throws -> [WedgeItem] { items }
    func save(_ items: [WedgeItem]) throws { self.items = items }
}

@Suite("Wedge persistence")
struct WedgeStorePersistenceTests {

    @Test("UserDefaults round-trip")
    func userDefaultsRoundTrip() throws {
        let suiteName = "wedge.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persistence = UserDefaultsWedgePersistence(defaults: defaults)
        let original = [
            WedgeItem(text: "One"),
            WedgeItem(text: "Two")
        ]
        try persistence.save(original)
        let loaded = try persistence.load()
        #expect(loaded.map(\.text) == ["One", "Two"])
        #expect(loaded.map(\.id) == original.map(\.id))
    }

    @Test("missing key loads as empty list")
    func missingKeyLoadsEmpty() throws {
        let suiteName = "wedge.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persistence = UserDefaultsWedgePersistence(defaults: defaults)
        #expect(try persistence.load().isEmpty)
    }

    @Test("save overwrites previous snapshot")
    func saveOverwrites() throws {
        let suiteName = "wedge.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persistence = UserDefaultsWedgePersistence(defaults: defaults)
        try persistence.save([WedgeItem(text: "Old")])
        try persistence.save([WedgeItem(text: "New")])
        #expect(try persistence.load().map(\.text) == ["New"])
    }

    @Test("corrupt payload fails decode")
    func corruptPayloadThrows() throws {
        let suiteName = "wedge.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(Data("not-json".utf8), forKey: "wedge.items")
        let persistence = UserDefaultsWedgePersistence(defaults: defaults)
        #expect(throws: DecodingError.self) {
            try persistence.load()
        }
    }

    @Test("store reload from persistence")
    func storeReload() throws {
        let persistence = MemoryPersistence()
        persistence.items = [WedgeItem(text: "Persisted")]
        let store = WedgeStore()
        store.replaceAll(try persistence.load())
        #expect(store.oneThing?.text == "Persisted")
    }

    @Test("empty persistence clears store via replaceAll")
    func emptyPersistenceClearsStore() throws {
        let store = WedgeStore()
        _ = try store.add("Gone")
        store.replaceAll([])
        #expect(store.oneThing == nil)
        #expect(store.items.isEmpty)
    }
}
