import Foundation

/// Single place for user-visible product language.
/// Change naming here — UI strings should reference these constants.
enum WedgeCopy {
    static let appName = "Wedge"

    // Product verbs / nouns (canonical language)
    static let done = "Done"
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

    // Shortcuts, Spotlight and Siri
    static let addToUpNextTitle = "Add to Up Next"
    static let markDoneTitle = "Mark Done"
    static let getNowTitle = "Get Now"
    static let textParameterTitle = "Text"
    static let addedToUpNext = "Added to Up Next."
    static let nothingToMarkDone = "Nothing to mark done."
    static func nowIs(_ text: String) -> String { "\(now): \(text)" }

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

    // Settings — groups
    static let menuBarSection = "Menu Bar"
    static let keyboardSection = "Keyboard"

    // Settings — menu bar
    static let bold = "Bold"
    static let color = "Color"
    static let automatic = "Automatic"
    static let custom = "Custom"

    // Settings — done sound
    static let playSound = "Play sound"
    static let sound = "Sound"
    static let defaultSoundName = "Pop (default)"
    static let preview = "Preview"
    static let chooseEllipsis = "Choose…"
    static let useDefault = "Use Default"
    static let soundTooLong = "That sound is longer than 3 seconds."
    static let soundUnreadable = "Couldn't read that sound file."
    /// Inline message for a custom sound that could not be installed. An unsupported file type,
    /// an unreadable file and a failed copy all read the same to the user.
    static func soundMessage(for error: any Error) -> String {
        switch error as? CustomSoundError {
        case .tooLong: soundTooLong
        case .unsupportedType, .unreadable, nil: soundUnreadable
        }
    }

    // Settings — keyboard
    static let showWedgeShortcut = "Show Wedge"
    static let reset = "Reset"

    // Settings — login item and about
    static let openAtLogin = "Open at login"
    static let openLoginItems = "Open Login Items"
    static let loginChangeFailed = "Couldn't change this. Check System Settings › General › Login Items."
    static func aboutVersion(_ version: String) -> String { "\(appName) \(version)" }
    static let gitHub = "GitHub"
    static let gitHubAddress = "https://github.com/adminALEX/wedge"
}
