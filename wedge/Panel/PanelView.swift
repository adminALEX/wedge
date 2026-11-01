import SwiftUI

/// Where keyboard focus is in the panel.
enum PanelFocus: Hashable {
    case add
    case list
    case row(UUID)
}

/// A row being edited in place, with its uncommitted text.
struct RowEdit: Equatable {
    let id: UUID
    var text: String
}

/// The panel content (spec §3.1, A1) on Liquid Glass: issue banner, the Now label and the list
/// (Now, Up Next), add field and hint row. Owns focus, selection, the add draft and the inline
/// edit, so ⌘Z can tell unsaved typing from Undo Done. Also plays the Done moment (§3.2): it
/// keeps the completed row in the Now slot until it has popped, and shows the undo hint.
struct PanelView: View {
    let store: WedgeStore
    let doneAction: DoneAction
    /// Posts a VoiceOver announcement (the same path `DoneAction` uses).
    let announce: (String) -> Void

    @Environment(PanelController.self) private var panel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The last Done whose completed row has left the Now slot.
    @State private var settledEventID: UUID?
    /// The Done the undo hint is showing for; nil once its time is up.
    @State private var hintEventID: UUID?
    @State private var draft = ""
    @State private var selection: UUID?
    @State private var edit: RowEdit?
    @FocusState private var focus: PanelFocus?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let issue = store.issue {
                IssueBanner(issue: issue)
            }
            if !store.items.isEmpty || completing != nil {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(WedgeCopy.now)
                    ItemList(
                        store: store,
                        doneAction: doneAction,
                        announce: announce,
                        completing: completing,
                        selection: $selection,
                        edit: $edit,
                        focus: $focus,
                        onLeaveBottom: focusAddField
                    )
                }
            }
            AddField(
                store: store,
                draft: $draft,
                focus: $focus,
                onMoveUp: selectLastRow,
                onClose: { panel.hide() }
            )
            Text(WedgeCopy.panelHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) {
                    if showsUndoHint { UndoHint().transition(.opacity) }
                }
        }
        .padding(12)
        .frame(width: PanelAnchor.width)
        .fixedSize(horizontal: false, vertical: true)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .background { shortcuts }
        .defaultFocus($focus, .add)
        .onChange(of: panel.isVisible) { _, isVisible in
            guard isVisible else { return }
            // Any Done so far happened while the panel was hidden: it never plays (R19).
            settledEventID = doneAction.lastEvent?.id
            focusAddField()
        }
        .onChange(of: store.items.isEmpty) { _, isEmpty in
            // The list went away (last row deleted or Done) and took focus with it.
            if isEmpty { focusAddField() }
        }
        .onChange(of: doneAction.lastEvent?.id) { _, id in doneArrived(id) }
        .task(id: doneAction.lastEvent?.id) { await riseAfterPop() }
        .task(id: hintEventID) { await expireUndoHint() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(WedgeCopy.appName)
    }

    /// Panel-wide shortcuts. Disabled buttons let the key go on (⌘Z then reaches the field's undo).
    private var shortcuts: some View {
        Group {
            Button(WedgeCopy.done) { doneAction.perform() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(store.now == nil)
            Button(WedgeCopy.settingsMenu) { panel.openSettings() }
                .keyboardShortcut(",", modifiers: .command)
            Button(WedgeCopy.undoDoneMenu) { doneAction.undo() }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(undoRoute != .done)
        }
        .focusable(false)
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var animatesDone: Bool {
        DoneMoment.animates(panelVisible: panel.isVisible, reduceMotion: reduceMotion)
    }

    /// Worked out in `body`, so the completed row holds the Now slot from the very first frame.
    private var completing: DoneEvent? {
        DoneMoment.completing(
            doneAction.lastEvent, settledID: settledEventID, items: store.items, animates: animatesDone)
    }

    private var showsUndoHint: Bool {
        DoneMoment.showsUndoHint(
            hintEventID: hintEventID, lastEventID: doneAction.lastEvent?.id, canUndoDone: store.canUndoDone)
    }

    /// Decides, as the Done arrives, whether it plays and shows the hint (`DoneMoment.arrival`).
    private func doneArrived(_ id: UUID?) {
        guard let id else { return }
        let arrival = DoneMoment.arrival(panelVisible: panel.isVisible, reduceMotion: reduceMotion)
        if arrival.settlesNow { settledEventID = id }
        if arrival.armsUndoHint {
            withAnimation(reduceMotion ? nil : DoneMoment.undoHintFade) { hintEventID = id }
        }
    }

    /// Lets the completed row pop, then removes it so the next row rises. A newer Done cancels
    /// this task and starts its own, so the moment restarts from the new state.
    private func riseAfterPop() async {
        guard let id = doneAction.lastEvent?.id, id != settledEventID, animatesDone else { return }
        do { try await Task.sleep(for: DoneMoment.popDuration) } catch { return }
        withAnimation(DoneMoment.rise) { settledEventID = id }
    }

    /// Hides "Undo Done ⌘Z" 4 s after it appears (sooner if undo is no longer possible).
    private func expireUndoHint() async {
        guard hintEventID != nil else { return }
        do { try await Task.sleep(for: DoneMoment.undoHintDuration) } catch { return }
        withAnimation(reduceMotion ? nil : DoneMoment.undoHintFade) { hintEventID = nil }
    }

    private var undoRoute: UndoRoute {
        UndoRoute.resolve(fieldHasUnsavedTyping: fieldHasUnsavedTyping, canUndoDone: store.canUndoDone)
    }

    /// The focused field's text differs from what is saved.
    private var fieldHasUnsavedTyping: Bool {
        switch focus {
        case .add:
            return !draft.isEmpty
        case .row(let id):
            guard let edit, edit.id == id else { return false }
            return store.items.first { $0.id == id }?.text != edit.text
        case .list, nil:
            return false
        }
    }

    private func focusAddField() {
        selection = nil
        focus = .add
    }

    /// ↑ from the add field enters the list at its last row.
    private func selectLastRow() {
        guard let last = store.items.last else { return }
        selection = last.id
        focus = .list
    }
}

/// The small section label ("Now", "Up Next").
struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
    }
}
