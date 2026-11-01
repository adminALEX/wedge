import AppIntents

/// A failure shown to the person running an intent; the message is the same copy the panel shows.
nonisolated struct WedgeIntentError: Error, Equatable, CustomLocalizedStringResourceConvertible {
    let message: String

    var localizedStringResource: LocalizedStringResource { "\(message)" }
}
