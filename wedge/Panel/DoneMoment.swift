import SwiftUI

/// The Done moment in the panel (spec §3.2, D1): the completed Now row's ring fills green and
/// checks, its title swells and pops out, then the row leaves and the next row rises into the
/// Now slot while the rows below shift up. About 450 ms in all; an instant swap under Reduce
/// Motion or while the panel is hidden. A new Done restarts from the new state, never queues.
enum DoneMoment {
    static let titleSpring = Animation.spring(response: 0.32, dampingFraction: 0.6)
    static let swellScale: CGFloat = 1.06
    static let popScale: CGFloat = 0.6
    /// From the ring's check to the start of the swell.
    static let ringBeat: Duration = .milliseconds(60)
    /// From the start of the swell to the start of the pop.
    static let swellDuration: Duration = .milliseconds(100)
    /// From the check until the completed row leaves and the next row starts to rise.
    static let popDuration: Duration = .milliseconds(280)
    /// The rise: removing the completed row and moving the rows below up.
    static let rise = Animation.spring(response: 0.18, dampingFraction: 1)
    static let undoHintDuration: Duration = .seconds(4)
    static let undoHintFade = Animation.easeOut(duration: 0.2)

    static func animates(panelVisible: Bool, reduceMotion: Bool) -> Bool {
        panelVisible && !reduceMotion
    }

    /// What a Done does in the panel, decided once, when it arrives.
    struct Arrival: Equatable {
        /// The completed row leaves at once (no pop, no rise).
        let settlesNow: Bool
        /// "Undo Done ⌘Z" is shown for this Done.
        let armsUndoHint: Bool
    }

    /// A Done while the panel is hidden never animates and never shows the hint later (R19);
    /// under Reduce Motion it swaps at once but still shows the hint.
    static func arrival(panelVisible: Bool, reduceMotion: Bool) -> Arrival {
        Arrival(
            settlesNow: !animates(panelVisible: panelVisible, reduceMotion: reduceMotion),
            armsUndoHint: panelVisible)
    }

    /// The event whose completed item still holds the Now slot: the last Done, until it has
    /// settled, unless it is not animated or its item is back in the list (Undo Done).
    static func completing(_ event: DoneEvent?, settledID: UUID?, items: [WedgeItem], animates: Bool) -> DoneEvent? {
        guard animates, let event, event.id != settledID,
            !items.contains(where: { $0.id == event.completed.id })
        else { return nil }
        return event
    }

    /// "Undo Done ⌘Z" shows for the latest Done only, and only while it can still be undone.
    static func showsUndoHint(hintEventID: UUID?, lastEventID: UUID?, canUndoDone: Bool) -> Bool {
        canUndoDone && hintEventID != nil && hintEventID == lastEventID
    }
}

/// The completed Now row during the Done moment. Each event gets fresh animation state.
struct DonePopRow: View {
    let event: DoneEvent

    var body: some View {
        Pop(item: event.completed).id(event.id)
    }

    private struct Pop: View {
        private enum Phase { case idle, checked, swell, pop }

        let item: WedgeItem
        @State private var phase = Phase.idle

        var body: some View {
            HStack(spacing: NowRowStyle.spacing) {
                Image(systemName: phase == .idle ? "circle" : "checkmark.circle.fill")
                    .font(NowRowStyle.ringFont)
                    .foregroundStyle(phase == .idle ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.green))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: phase == .idle)
                Text(item.text)
                    .font(NowRowStyle.titleFont)
                    .lineLimit(1)
                    .padding(.horizontal, NowRowStyle.titlePadding)
                    .scaleEffect(scale, anchor: .leading)
                    .opacity(phase == .pop ? 0 : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .task {
                withAnimation(DoneMoment.titleSpring) { phase = .checked }
                do { try await Task.sleep(for: DoneMoment.ringBeat) } catch { return }
                withAnimation(DoneMoment.titleSpring) { phase = .swell }
                do { try await Task.sleep(for: DoneMoment.swellDuration) } catch { return }
                withAnimation(DoneMoment.titleSpring) { phase = .pop }
            }
        }

        private var scale: CGFloat {
            switch phase {
            case .idle, .checked: 1
            case .swell: DoneMoment.swellScale
            case .pop: DoneMoment.popScale
            }
        }
    }
}
