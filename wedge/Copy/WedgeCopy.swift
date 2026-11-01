import Foundation

/// Single place for user-visible product language.
/// Change naming here — UI strings should reference these constants.
enum WedgeCopy {
    static let appName = "Wedge"

    // Product verbs / nouns (canonical language)
    static let done = "Done"
    static let oneThing = "one thing"
    static let upNext = "Up next"
    static let delete = "Delete"

    // Panel
    static let addOneThingPlaceholder = "What's your one thing?"
    static let addUpNextPlaceholder = "Add to up next…"
    static let itemFieldAccessibility = "Item"
    static let dragToReorder = "Drag to reorder"

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
