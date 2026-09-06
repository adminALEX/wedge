import Testing
@testable import wedge

@Suite("WedgeCopy")
struct WedgeCopyTests {
    @Test("canonical product words are non-empty and stable")
    func canonicalWords() {
        #expect(!WedgeCopy.appName.isEmpty)
        #expect(WedgeCopy.done == "Done")
        #expect(WedgeCopy.oneThing == "one thing")
        #expect(WedgeCopy.upNext == "Up next")
        #expect(WedgeCopy.addOneThingPlaceholder.contains(WedgeCopy.oneThing))
        #expect(WedgeCopy.addUpNextPlaceholder.lowercased().contains("up next"))
        #expect(WedgeCopy.doneShortcut == WedgeCopy.done)
        #expect(WedgeCopy.quitMenu.contains(WedgeCopy.appName))
        #expect(WedgeCopy.soundFooter.contains(WedgeCopy.done))
    }
}
