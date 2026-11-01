/// The reply to an intent that changed the list. When that change won't be kept (a failed save,
/// or a list Wedge couldn't read), the panel's banner text follows the reply, so the person
/// running the shortcut learns it too.
enum IntentReply {
    static func afterChange(_ message: String, store: WedgeStore) -> String {
        guard let issue = store.issue, issue == .saveFailed || issue == .loadFailed else { return message }
        return "\(message) \(IssueBanner.message(for: issue))"
    }
}
