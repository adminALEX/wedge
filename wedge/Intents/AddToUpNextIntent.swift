import AppIntents

/// Appends to Up Next (or becomes Now when the list is empty), with the panel's validation.
nonisolated struct AddToUpNextIntent: AppIntent {
    static let title: LocalizedStringResource = "Add to Up Next"
    static let openAppWhenRun = false

    @Parameter(title: "Text")
    var text: String

    @Dependency var store: WedgeStore

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let message = try Self.run(text: text, store: store)
        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }

    /// Returns "Now: ‹text›" when the item became Now, else "Added to Up Next."; throws the panel's message on invalid text.
    @MainActor
    static func run(text: String, store: WedgeStore) throws -> String {
        let wasEmpty = store.items.isEmpty
        do {
            let item = try store.add(text)
            return wasEmpty ? WedgeCopy.nowIs(item.text) : WedgeCopy.addedToUpNext
        } catch {
            throw WedgeIntentError(message: WedgeCopy.message(for: error))
        }
    }
}
