import Foundation

/// Single place for user-visible product language.
/// Change naming here — UI strings should reference these constants.
enum WedgeCopy {
    static let appName = "Wedge"

    // Product verbs / nouns (canonical language)
    static let done = "Done"
    static let oneThing = "one thing"
    static let now = "Now"
    static let upNext = "Up Next"
    static let delete = "Delete"

    // Panel
    static let addNowPlaceholder = "What are you on now?"
    static let addUpNextPlaceholder = "Add to Up Next…"
    static let panelHint = "⌘↩ Done · ⌘, Settings"
    static let undoHint = "Undo Done ⌘Z"
    static let maxCharacters = "40 characters max"
    static let cantBeEmpty = "Can't be empty"
    static let moveUp = "Move Up"
    static let moveDown = "Move Down"
    static func nowAccessibility(_ title: String) -> String { "\(now), \(title)" }
    static func doneAccessibility(_ title: String) -> String { "\(done), \(title)" }
    static func rowAccessibility(_ position: Int, of count: Int, _ title: String) -> String {
        "\(position) of \(count), \(title)"
    }
    static func movedTo(_ position: Int) -> String { "Moved to \(position)" }
    /// Inline message for a rejected add or edit (the store only throws `WedgeStoreError`).
    static func message(for error: any Error) -> String {
        switch error as? WedgeStoreError {
        case .textTooLong: maxCharacters
        case .emptyText, nil: cantBeEmpty
        }
    }

    // Panel — store issues
    static let saveFailed = "Couldn't save. Your latest changes may be lost."
    static let recoveredFromCorruptFile = "Couldn't read your list. A copy was saved in Application Support."
    static let loadFailed = "Couldn't read your list. Changes won't be saved until Wedge can read it."

    // Status item / menu
    static let settingsMenu = "Settings…"
    static var quitMenu: String { "Quit \(appName)" }
    static let undoDoneMenu = "Undo Done"
    static func statusItemNow(_ title: String) -> String { "\(appName), Now: \(title)" }
    static let statusItemNothingNow = "\(appName), nothing now"

    // Settings — appearance
    static let bold = "Bold"
    static let automaticColor = "Automatic color"
    static let color = "Color"
    static let appearanceFooter =
        "Applies to the \(oneThing) in the menu bar. Automatic follows the system label color."

    // Settings — sound
    static let soundSection = "Sound"
    static let playSound = "Play sound"
    static let defaultPopSound = "Default pop sound"
    static func customPopSoundLabel(_ fileName: String) -> String { "Custom: \(fileName)" }
    static let preview = "Preview"
    static let chooseEllipsis = "Choose…"
    static let useDefault = "Use default"
    static var soundFooter: String {
        "Played when you mark \(done). Custom files must be 3 seconds or shorter (AIFF, WAV, MP3, M4A, or CAF)."
    }

    // Settings — general
    static let generalSection = "General"
    static let launchAtLogin = "Launch at login"
    static let launchAtLoginFooter =
        "Starts \(appName) automatically when you log in to your Mac."

    // Settings — keyboard
    static let keyboardShortcutsSection = "Keyboard shortcuts"
    static let showWedgeShortcut = "Show Wedge"
    static var doneShortcut: String { done }
    static let resetToDefaults = "Reset to defaults"
}
