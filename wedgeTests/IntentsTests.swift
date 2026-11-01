import Foundation
import Testing

@testable import wedge

@Suite("Intents")
@MainActor
struct IntentsTests {
    private func doneAction(for store: WedgeStore) throws -> (DoneAction, cleanup: () -> Void) {
        let suiteName = "wedge.tests.intents.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let action = DoneAction(
            store: store,
            settings: WedgeSettings(defaults: defaults),
            sound: SpySoundPlayer(),
            announce: { _ in }
        )
        return (action, { defaults.removePersistentDomain(forName: suiteName) })
    }

    // MARK: Add to Up Next

    @Test func addRejectsEmptyText() {
        let list = store([])
        #expect(throws: WedgeIntentError(message: "Can't be empty")) {
            try AddToUpNextIntent.run(text: "", store: list)
        }
        #expect(list.items.isEmpty)
    }

    @Test func addRejectsTextOverTheLimit() {
        let list = store(["A"])
        #expect(throws: WedgeIntentError(message: "40 characters max")) {
            try AddToUpNextIntent.run(text: String(repeating: "x", count: 41), store: list)
        }
        #expect(list.items.count == 1)
    }

    @Test func addToEmptyListBecomesNow() throws {
        let list = store([])
        #expect(try AddToUpNextIntent.run(text: "A", store: list) == "Now: A")
        #expect(list.now?.text == "A")
    }

    @Test func addToNonEmptyListAppends() throws {
        let list = store(["A"])
        #expect(try AddToUpNextIntent.run(text: "B", store: list) == "Added to Up Next.")
        #expect(list.items.map(\.text) == ["A", "B"])
    }

    @Test func addAppendsTheBannerWhenTheSaveFails() throws {
        let persister = InMemoryWedgePersistence(items: [WedgeItem(text: "A")])
        persister.failSaves = true
        let list = WedgeStore(persister: persister)
        #expect(
            try AddToUpNextIntent.run(text: "B", store: list)
                == "Added to Up Next. Couldn't save. Your latest changes may be lost.")
    }

    @Test func addAppendsTheBannerWhenTheListCouldNotBeRead() throws {
        let list = WedgeStore(persister: FailingLoadPersistence(error: CocoaError(.fileReadUnknown)))
        #expect(list.issue == .loadFailed)
        #expect(
            try AddToUpNextIntent.run(text: "A", store: list)
                == "Now: A Couldn't read your list. Changes won't be saved until Wedge can read it.")
    }

    // MARK: Mark Done

    @Test func markDoneAppendsTheBannerWhenTheSaveFails() throws {
        let persister = InMemoryWedgePersistence(items: ["A", "B"].map { WedgeItem(text: $0) })
        persister.failSaves = true
        let list = WedgeStore(persister: persister)
        let (action, cleanup) = try doneAction(for: list)
        defer { cleanup() }
        #expect(
            MarkDoneIntent.run(doneAction: action, store: list)
                == "Done. Now: B Couldn't save. Your latest changes may be lost.")
    }

    @Test func markDoneAnnouncesTheNextItem() throws {
        let list = store(["A", "B"])
        let (action, cleanup) = try doneAction(for: list)
        defer { cleanup() }
        #expect(MarkDoneIntent.run(doneAction: action, store: list) == "Done. Now: B")
        #expect(list.now?.text == "B")
    }

    @Test func markDoneOnLastItemSaysNothingUpNext() throws {
        let list = store(["A"])
        let (action, cleanup) = try doneAction(for: list)
        defer { cleanup() }
        #expect(MarkDoneIntent.run(doneAction: action, store: list) == "Done. Nothing up next.")
    }

    @Test func markDoneOnEmptyListSaysNothingToMarkDone() throws {
        let list = store([])
        let (action, cleanup) = try doneAction(for: list)
        defer { cleanup() }
        #expect(MarkDoneIntent.run(doneAction: action, store: list) == "Nothing to mark done.")
    }

    // MARK: Get Now

    @Test func getNowReturnsTheNowTitle() {
        #expect(GetNowIntent.run(store: store(["A", "B"])) == "A")
    }

    @Test func getNowIsEmptyWhenThereIsNone() {
        #expect(GetNowIntent.run(store: store([])) == "")
    }

    // MARK: Copy

    @Test func intentTitlesMatchTheCopy() {
        #expect(String(localized: AddToUpNextIntent.title) == WedgeCopy.addToUpNextTitle)
        #expect(String(localized: MarkDoneIntent.title) == WedgeCopy.markDoneTitle)
        #expect(String(localized: GetNowIntent.title) == WedgeCopy.getNowTitle)
    }

    @Test func intentsRunInTheBackground() {
        #expect(AddToUpNextIntent.openAppWhenRun == false)
        #expect(MarkDoneIntent.openAppWhenRun == false)
        #expect(GetNowIntent.openAppWhenRun == false)
    }
}
