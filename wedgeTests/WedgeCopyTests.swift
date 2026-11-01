import Testing
@testable import wedge

@Suite("WedgeCopy")
@MainActor
struct WedgeCopyTests {
    @Test("canonical product words are non-empty and stable")
    func canonicalWords() {
        #expect(!WedgeCopy.appName.isEmpty)
        #expect(WedgeCopy.done == "Done")
        #expect(WedgeCopy.oneThing == "one thing")
        #expect(WedgeCopy.now == "Now")
        #expect(WedgeCopy.upNext == "Up Next")
        #expect(WedgeCopy.addNowPlaceholder == "What are you on now?")
        #expect(WedgeCopy.addUpNextPlaceholder == "Add to Up Next…")
        #expect(WedgeCopy.doneShortcut == WedgeCopy.done)
        #expect(WedgeCopy.quitMenu.contains(WedgeCopy.appName))
        #expect(WedgeCopy.soundFooter.contains(WedgeCopy.done))
    }

    @Test("panel copy matches the spec")
    func panelCopy() {
        #expect(WedgeCopy.panelHint == "⌘↩ Done · ⌘, Settings")
        #expect(WedgeCopy.maxCharacters == "40 characters max")
        #expect(WedgeCopy.cantBeEmpty == "Can't be empty")
        #expect(WedgeCopy.nowAccessibility("Ship it") == "Now, Ship it")
        #expect(WedgeCopy.doneAccessibility("Ship it") == "Done, Ship it")
        #expect(WedgeCopy.rowAccessibility(2, of: 5, "Ship it") == "2 of 5, Ship it")
        #expect(WedgeCopy.movedTo(3) == "Moved to 3")
        #expect(WedgeCopy.message(for: WedgeStoreError.emptyText) == "Can't be empty")
        #expect(WedgeCopy.message(for: WedgeStoreError.textTooLong(max: 40)) == "40 characters max")
        #expect(IssueBanner.message(for: .saveFailed) == "Couldn't save. Your latest changes may be lost.")
        #expect(
            IssueBanner.message(for: .recoveredFromCorruptFile)
                == "Couldn't read your list. A copy was saved in Application Support."
        )
        #expect(
            IssueBanner.message(for: .loadFailed)
                == "Couldn't read your list. Changes won't be saved until Wedge can read it."
        )
    }
}
