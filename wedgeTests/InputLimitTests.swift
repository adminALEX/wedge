import Testing
@testable import wedge

@Suite("InputLimit")
@MainActor
struct InputLimitTests {
    @Test func counterHiddenBelowThirty() {
        #expect(InputLimit.counter(for: String(repeating: "a", count: 29)) == nil)
    }

    @Test func counterShownFromThirty() {
        #expect(InputLimit.counter(for: String(repeating: "a", count: 34)) == "34/40")
    }

    @Test func counterCountsGraphemes() {
        #expect(InputLimit.counter(for: String(repeating: "👨‍👩‍👧‍👦", count: 30)) == "30/40")
    }

    @Test func refusesOverLimitPaste() {
        let r = InputLimit.filter(proposed: String(repeating: "a", count: 41), previous: "abc")
        #expect(r == ("abc", true))
    }

    @Test func acceptsAtLimit() {
        let s = String(repeating: "a", count: 40)
        #expect(InputLimit.filter(proposed: s, previous: "").text == s)
    }

    @Test func overLimitPasteRevertsAndStaysRefused() {
        let long = String(repeating: "a", count: 41)
        let paste = InputLimit.change(old: "abc", new: long)
        #expect(paste?.text == "abc")
        #expect(paste?.refused == true)
        // The revert pass (long → "abc") is skipped, so `refused` keeps its value.
        #expect(InputLimit.change(old: long, new: "abc") == nil)
    }

    @Test func acceptedChangeClearsRefused() {
        let typed = InputLimit.change(old: "ab", new: "abc")
        #expect(typed?.text == "abc")
        #expect(typed?.refused == false)
    }
}
