import AppIntents

/// Returns the Now item's text, for use in other shortcuts.
struct GetNowIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Now"
    static let openAppWhenRun = false

    @Dependency var store: WedgeStore

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: Self.run(store: store))
    }

    /// The Now item's text; empty when there is none.
    @MainActor
    static func run(store: WedgeStore) -> String {
        store.now?.text ?? ""
    }
}
