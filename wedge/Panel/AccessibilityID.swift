/// Accessibility identifiers the UI tests find the panel's views by (not user-facing copy).
enum AccessibilityID {
    static let nowHeader = "nowHeader"
    static let addField = "addField"

    /// An Up Next row by its displayed position (Up Next starts at 2; Now is 1).
    static func upNextRow(_ position: Int) -> String { "upNextRow-\(position)" }
}
