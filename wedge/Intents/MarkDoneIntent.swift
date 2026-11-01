import AppIntents

/// Runs the same Done path as the panel and menu bar: sound, menu-bar bump and panel animation.
nonisolated struct MarkDoneIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Done"
    static let openAppWhenRun = false

    @Dependency var store: WedgeStore
    @Dependency var doneAction: DoneAction

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let message = Self.run(doneAction: doneAction, store: store)
        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }

    /// Returns the Done announcement, or "Nothing to mark done." on an empty list.
    @MainActor
    static func run(doneAction: DoneAction, store: WedgeStore) -> String {
        guard store.now != nil, let event = doneAction.perform() else {
            return WedgeCopy.nothingToMarkDone
        }
        return DoneAction.announcement(for: event)
    }
}
