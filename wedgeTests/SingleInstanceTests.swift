import Foundation
import Testing

@testable import wedge

@Suite("SingleInstance")
@MainActor
struct SingleInstanceTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000)

    private func copy(_ pid: pid_t, at offset: TimeInterval?, terminated: Bool = false) -> SingleInstance.Copy {
        SingleInstance.Copy(
            processID: pid, launchDate: offset.map { start.addingTimeInterval($0) }, isTerminated: terminated)
    }

    @Test func aloneKeepsRunning() {
        let me = copy(10, at: 0)
        #expect(SingleInstance.handOffTarget(current: me, running: [me]) == nil)
    }

    @Test func newerCopyHandsOffToTheOlderOne() {
        let old = copy(10, at: 0)
        let new = copy(20, at: 5)
        #expect(SingleInstance.handOffTarget(current: new, running: [old, new]) == old)
    }

    @Test func olderCopyKeepsRunning() {
        let old = copy(10, at: 0)
        let new = copy(20, at: 5)
        #expect(SingleInstance.handOffTarget(current: old, running: [old, new]) == nil)
    }

    @Test func simultaneousLaunchLeavesExactlyOneByProcessID() {
        let low = copy(10, at: 0)
        let high = copy(20, at: 0)
        let running = [low, high]
        #expect(SingleInstance.handOffTarget(current: high, running: running) == low)
        #expect(SingleInstance.handOffTarget(current: low, running: running) == nil)
    }

    @Test func terminatedCopiesAreSkipped() {
        let quitting = copy(10, at: 0, terminated: true)
        let me = copy(20, at: 5)
        #expect(SingleInstance.handOffTarget(current: me, running: [quitting, me]) == nil)
    }

    @Test func handsOffToTheOldestOfSeveral() {
        let oldest = copy(30, at: 0)
        let middle = copy(10, at: 2)
        let me = copy(20, at: 5)
        #expect(SingleInstance.handOffTarget(current: me, running: [middle, me, oldest]) == oldest)
    }

    @Test func unknownLaunchDateCountsAsOldest() {
        let unknown = copy(30, at: nil)
        let me = copy(20, at: 0)
        #expect(SingleInstance.handOffTarget(current: me, running: [unknown, me]) == unknown)
        #expect(SingleInstance.handOffTarget(current: unknown, running: [unknown, me]) == nil)
    }
}
