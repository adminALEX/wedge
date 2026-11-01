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
}
