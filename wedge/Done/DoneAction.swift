import Foundation
import Observation
import os

struct DoneEvent: Equatable {
    let id: UUID
    let completed: WedgeItem
    let next: WedgeItem?
}

/// The single Done path: completes the current item, plays the sound, and announces the result.
@Observable
final class DoneAction {
    private(set) var lastEvent: DoneEvent?

    @ObservationIgnored private let store: WedgeStore
    @ObservationIgnored private let settings: WedgeSettings
    @ObservationIgnored private let sound: any DoneSoundPlaying
    @ObservationIgnored private let announce: (String) -> Void

    init(
        store: WedgeStore,
        settings: WedgeSettings,
        sound: any DoneSoundPlaying,
        announce: @escaping (String) -> Void
    ) {
        self.store = store
        self.settings = settings
        self.sound = sound
        self.announce = announce
    }

    /// Completes the current item. Returns nil, and does nothing else, when there is none.
    @discardableResult
    func perform() -> DoneEvent? {
        let interval = Log.signposter.beginInterval("Done")
        defer { Log.signposter.endInterval("Done", interval) }

        guard let completed = store.completeNow() else { return nil }
        let event = DoneEvent(id: UUID(), completed: completed, next: store.now)
        lastEvent = event
        if settings.playsSound { sound.play() }
        announce(Self.announcement(for: event))
        Log.done.debug("Done performed")
        return event
    }

    /// Puts the last completed item back at the front.
    @discardableResult
    func undo() -> Bool {
        store.undoDone()
    }

    static func announcement(for event: DoneEvent) -> String {
        if let next = event.next {
            return WedgeCopy.doneNowAnnouncement(next.text)
        }
        return WedgeCopy.doneNothingUpNextAnnouncement
    }
}
