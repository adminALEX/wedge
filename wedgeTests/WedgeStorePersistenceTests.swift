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

    @Test("store reload from persistence")
    func storeReload() throws {
        let persistence = MemoryPersistence()
        persistence.items = [WedgeItem(text: "Persisted")]
        let store = WedgeStore()
        store.replaceAll(try persistence.load())
        #expect(store.oneThing?.text == "Persisted")
    }
}
