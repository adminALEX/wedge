import SwiftUI

/// The Done moment in the panel (spec §3.2, D1): the completed Now row's ring fills green and
/// checks, its title swells and pops out, then the row leaves and the next row rises into the
/// Now slot while the rows below shift up. About 450 ms in all; an instant swap under Reduce
/// Motion or while the panel is hidden. A new Done restarts from the new state, never queues.
enum DoneMoment {
    static let titleSpring = Animation.spring(response: 0.32, dampingFraction: 0.6)
    static let swellScale: CGFloat = 1.06
    static let popScale: CGFloat = 0.6
    /// From the check to the start of the pop.
    static let swellDuration: Duration = .milliseconds(100)
    /// From the check until the completed row leaves and the next row starts to rise.
    static let popDuration: Duration = .milliseconds(250)
    /// The rise: removing the completed row and moving the rows below up.
    static let rise = Animation.spring(response: 0.2, dampingFraction: 1)
    static let undoHintDuration: Duration = .seconds(4)
    static let undoHintFade = Animation.easeOut(duration: 0.2)

    static func animates(panelVisible: Bool, reduceMotion: Bool) -> Bool {
        panelVisible && !reduceMotion
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
        private enum Phase { case idle, swell, pop }

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
                withAnimation(DoneMoment.titleSpring) { phase = .swell }
                do { try await Task.sleep(for: DoneMoment.swellDuration) } catch { return }
                withAnimation(DoneMoment.titleSpring) { phase = .pop }
            }
        }

        private var scale: CGFloat {
            switch phase {
            case .idle: 1
            case .swell: DoneMoment.swellScale
            case .pop: DoneMoment.popScale
            }
        }
    }
}
