import Foundation
import Testing
@testable import wedge

@Suite("DoneMoment")
@MainActor
struct DoneMomentTests {
    private let completed = WedgeItem(text: "Ship it")
    private let next = WedgeItem(text: "Review PR")

    private var event: DoneEvent { DoneEvent(id: UUID(), completed: completed, next: next) }

    @Test func animatesOnlyWhenVisibleWithoutReduceMotion() {
        #expect(DoneMoment.animates(panelVisible: true, reduceMotion: false))
        #expect(!DoneMoment.animates(panelVisible: true, reduceMotion: true))
        #expect(!DoneMoment.animates(panelVisible: false, reduceMotion: false))
    }

    @Test func doneWhileHiddenSettlesAtOnceWithoutHint() {
        let arrival = DoneMoment.arrival(panelVisible: false, reduceMotion: false)
        #expect(arrival == DoneMoment.Arrival(settlesNow: true, armsUndoHint: false))
        #expect(!DoneMoment.arrival(panelVisible: false, reduceMotion: true).armsUndoHint)
    }

    @Test func doneWhileVisibleAnimatesAndArmsHint() {
        let arrival = DoneMoment.arrival(panelVisible: true, reduceMotion: false)
        #expect(arrival == DoneMoment.Arrival(settlesNow: false, armsUndoHint: true))
    }

    @Test func doneUnderReduceMotionSwapsAtOnceButShowsHint() {
        let arrival = DoneMoment.arrival(panelVisible: true, reduceMotion: true)
        #expect(arrival == DoneMoment.Arrival(settlesNow: true, armsUndoHint: true))
    }

    @Test func unsettledEventHoldsTheNowSlot() {
        let event = event
        #expect(DoneMoment.completing(event, settledID: nil, items: [next], animates: true) == event)
    }

    @Test func settledEventIsGone() {
        let event = event
        #expect(DoneMoment.completing(event, settledID: event.id, items: [next], animates: true) == nil)
    }

    @Test func reduceMotionOrHiddenPanelSwapsInstantly() {
        #expect(DoneMoment.completing(event, settledID: nil, items: [next], animates: false) == nil)
    }

    @Test func undoneItemIsNotShownTwice() {
        #expect(DoneMoment.completing(event, settledID: nil, items: [completed, next], animates: true) == nil)
    }

    @Test func newerDoneRestartsFromTheNewState() {
        let first = event
        let second = DoneEvent(id: UUID(), completed: next, next: nil)
        #expect(DoneMoment.completing(second, settledID: first.id, items: [], animates: true) == second)
    }

    @Test func undoHintShowsForLatestDoneWhileUndoable() {
        let id = UUID()
        #expect(DoneMoment.showsUndoHint(hintEventID: id, lastEventID: id, canUndoDone: true))
        #expect(!DoneMoment.showsUndoHint(hintEventID: id, lastEventID: id, canUndoDone: false))
        #expect(!DoneMoment.showsUndoHint(hintEventID: nil, lastEventID: id, canUndoDone: true))
        #expect(!DoneMoment.showsUndoHint(hintEventID: id, lastEventID: UUID(), canUndoDone: true))
        #expect(!DoneMoment.showsUndoHint(hintEventID: nil, lastEventID: nil, canUndoDone: true))
    }

    @Test func timingMatchesSpec() {
        #expect(DoneMoment.swellScale == 1.06)
        #expect(DoneMoment.popScale == 0.6)
        #expect(DoneMoment.undoHintDuration == .seconds(4))
        #expect(DoneMoment.ringBeat == .milliseconds(60))
        #expect(DoneMoment.ringBeat + DoneMoment.swellDuration < DoneMoment.popDuration)
    }
}
