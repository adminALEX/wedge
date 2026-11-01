import Foundation
import Testing
@testable import wedge

@Suite("DoneAction")
@MainActor
struct DoneActionTests {
    private final class Announcements {
        var said: [String] = []
    }

    private struct Rig {
        let action: DoneAction
        let store: WedgeStore
        let settings: WedgeSettings
        let spy: SpySoundPlayer
        let announcements: Announcements
        let cleanup: () -> Void
    }

    private func make(_ texts: [String]) throws -> Rig {
        let suiteName = "wedge.tests.done.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let settings = WedgeSettings(defaults: defaults)
        let wedgeStore = store(texts)
        let spy = SpySoundPlayer()
        let announcements = Announcements()
        let action = DoneAction(
            store: wedgeStore,
            settings: settings,
            sound: spy,
            announce: { announcements.said.append($0) }
        )
        return Rig(
            action: action,
            store: wedgeStore,
            settings: settings,
            spy: spy,
            announcements: announcements,
            cleanup: { defaults.removePersistentDomain(forName: suiteName) }
        )
    }

    @Test func completesPlaysAndEmits() throws {
        let rig = try make(["A", "B"])
        defer { rig.cleanup() }
        let event = rig.action.perform()
        #expect(event?.completed.text == "A")
        #expect(event?.next?.text == "B")
        #expect(rig.store.now?.text == "B")
        #expect(rig.spy.plays == 1)
        #expect(rig.action.lastEvent == event)
    }

    @Test func silentWhenSoundOff() throws {
        let rig = try make(["A", "B"])
        defer { rig.cleanup() }
        rig.settings.playsSound = false
        rig.action.perform()
        #expect(rig.spy.plays == 0)
        #expect(rig.store.now?.text == "B")
    }

    @Test func noOpWhenEmpty() throws {
        let rig = try make([])
        defer { rig.cleanup() }
        #expect(rig.action.perform() == nil)
        #expect(rig.spy.plays == 0)
        #expect(rig.action.lastEvent == nil)
        #expect(rig.announcements.said.isEmpty)
    }

    @Test func rapidDoneCompletesInOrder() throws {
        let rig = try make(["A", "B", "C", "D"])
        defer { rig.cleanup() }
        let completed = [rig.action.perform(), rig.action.perform(), rig.action.perform()]
            .map { $0?.completed.text }
        #expect(completed == ["A", "B", "C"])
        #expect(rig.action.undo())
        #expect(rig.store.items.map(\.text) == ["C", "D"])
    }

    @Test func eachPerformGetsAFreshEventID() throws {
        let rig = try make(["A", "B"])
        defer { rig.cleanup() }
        let first = rig.action.perform()
        let second = rig.action.perform()
        #expect(first?.id != second?.id)
    }

    @Test func announcementCopy() {
        #expect(
            DoneAction.announcement(for: .init(id: UUID(), completed: .init(text: "A"), next: .init(text: "B")))
                == "Done. Now: B"
        )
        #expect(
            DoneAction.announcement(for: .init(id: UUID(), completed: .init(text: "A"), next: nil))
                == "Done. Nothing up next."
        )
    }

    @Test func announcesOnPerform() throws {
        let rig = try make(["A", "B"])
        defer { rig.cleanup() }
        rig.action.perform()
        #expect(rig.announcements.said == ["Done. Now: B"])
    }
}
