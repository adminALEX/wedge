import Foundation

protocol WedgePersisting: Sendable {
    func load() throws -> [WedgeItem]
    func save(_ items: [WedgeItem]) throws
}

struct UserDefaultsWedgePersistence: WedgePersisting {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "wedge.items") {
        self.defaults = defaults
        self.key = key
    }

    func load() throws -> [WedgeItem] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([WedgeItem].self, from: data)
    }

    func save(_ items: [WedgeItem]) throws {
        let data = try JSONEncoder().encode(items)
        defaults.set(data, forKey: key)
    }
}
