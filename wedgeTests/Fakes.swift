import Foundation

@testable import wedge

/// A store over in-memory persistence, pre-filled with items of the given texts.
@MainActor
func store(_ texts: [String]) -> WedgeStore {
    WedgeStore(persister: InMemoryWedgePersistence(items: texts.map { WedgeItem(text: $0) }))
}

/// A persister whose `load()` always throws `error`.
@MainActor
final class FailingLoadPersistence: WedgePersisting {
    let error: Error
    private(set) var saveCount = 0

    init(error: Error) {
        self.error = error
    }

    func load() throws -> [WedgeItem] { throw error }
    func save(_ items: [WedgeItem]) throws { saveCount += 1 }
}

/// Counts `play()` calls and records `load(customURL:)` arguments.
@MainActor
final class SpySoundPlayer: DoneSoundPlaying {
    private(set) var plays = 0
    private(set) var loads: [URL?] = []

    func play() { plays += 1 }
    func load(customURL: URL?) { loads.append(customURL) }
}
