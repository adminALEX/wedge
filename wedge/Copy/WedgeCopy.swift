import Foundation

/// Single place for user-visible product language.
/// Change naming here — UI strings should reference these members. Every translatable member
/// resolves through the String Catalog (`Localizable.xcstrings`) by a stable dotted key; the
/// `defaultValue` is the English copy and must match the catalog's `en` value.
///
/// App Intents metadata (titles, parameter titles, dialogs, App Shortcut phrases) is the one
/// exception: AppIntents needs compile-time literals, so those stay in `wedge/Intents`.
enum WedgeCopy {
    /// The product name. A brand name, so it is never translated.
    static let appName = "Wedge"

    // Product verbs / nouns (canonical language)
    static var done: String { String(localized: "product.done", defaultValue: "Done") }
    static var now: String { String(localized: "product.now", defaultValue: "Now") }
    static var upNext: String { String(localized: "product.upNext", defaultValue: "Up Next") }
    static var delete: String { String(localized: "product.delete", defaultValue: "Delete") }

    // Panel
    static var addNowPlaceholder: String {
        String(localized: "panel.addPlaceholder.empty", defaultValue: "What are you on now?")
    }
    static var addUpNextPlaceholder: String {
        String(localized: "panel.addPlaceholder.upNext", defaultValue: "Add to Up Next…")
    }
    static var panelHint: String {
        String(localized: "panel.hint", defaultValue: "⌘↩ Done · ⌘, Settings")
    }
    static var undoHint: String { String(localized: "panel.undoHint", defaultValue: "Undo Done ⌘Z") }
    static var maxCharacters: String {
        String(localized: "panel.error.maxCharacters", defaultValue: "40 characters max")
    }
    static var cantBeEmpty: String {
        String(localized: "panel.error.cantBeEmpty", defaultValue: "Can't be empty")
    }
    static var moveUp: String { String(localized: "panel.action.moveUp", defaultValue: "Move Up") }
    static var moveDown: String { String(localized: "panel.action.moveDown", defaultValue: "Move Down") }
    static func nowAccessibility(_ title: String) -> String {
        String(localized: "panel.accessibility.now", defaultValue: "\(now), \(title)")
    }
    static func doneAccessibility(_ title: String) -> String {
        String(localized: "panel.accessibility.done", defaultValue: "\(done), \(title)")
    }
    static func rowAccessibility(_ position: Int, of count: Int, _ title: String) -> String {
        String(
            localized: "panel.accessibility.row",
            defaultValue: "\(position) of \(count), \(title)"
        )
    }
    static func movedTo(_ position: Int) -> String {
        String(localized: "panel.announcement.movedTo", defaultValue: "Moved to \(position)")
    }
    /// Inline message for a rejected add or edit (the store only throws `WedgeStoreError`).
    static func message(for error: any Error) -> String {
        switch error as? WedgeStoreError {
        case .textTooLong: maxCharacters
        case .emptyText, nil: cantBeEmpty
        }
    }

    // Done announcements (VoiceOver and the Mark Done shortcut's reply)
    static func doneNowAnnouncement(_ text: String) -> String {
        String(localized: "done.announcement.now", defaultValue: "Done. Now: \(text)")
    }
    static var doneNothingUpNextAnnouncement: String {
        String(localized: "done.announcement.nothingUpNext", defaultValue: "Done. Nothing up next.")
    }

    // Shortcuts, Spotlight and Siri (the intents' own metadata stays literal in wedge/Intents)
    static var addToUpNextTitle: String {
        String(localized: "intent.addToUpNext.title", defaultValue: "Add to Up Next")
    }
    static var markDoneTitle: String {
        String(localized: "intent.markDone.title", defaultValue: "Mark Done")
    }
    static var getNowTitle: String { String(localized: "intent.getNow.title", defaultValue: "Get Now") }
    static var addedToUpNext: String {
        String(localized: "intent.addToUpNext.added", defaultValue: "Added to Up Next.")
    }
    static var nothingToMarkDone: String {
        String(localized: "intent.markDone.nothing", defaultValue: "Nothing to mark done.")
    }
    static func nowIs(_ text: String) -> String {
        String(localized: "intent.nowIs", defaultValue: "\(now): \(text)")
    }

    // Panel — store issues
    static var saveFailed: String {
        String(
            localized: "panel.issue.saveFailed",
            defaultValue: "Couldn't save. Your latest changes may be lost."
        )
    }
    static var recoveredFromCorruptFile: String {
        String(
            localized: "panel.issue.recoveredFromCorruptFile",
            defaultValue: "Couldn't read your list. A copy was saved in Application Support."
        )
    }
    static var loadFailed: String {
        String(
            localized: "panel.issue.loadFailed",
            defaultValue: "Couldn't read your list. Changes won't be saved until Wedge can read it."
        )
    }

    // Status item / menu
    static var settingsMenu: String { String(localized: "menu.settings", defaultValue: "Settings…") }
    static var quitMenu: String {
        String(localized: "menu.quit", defaultValue: "Quit \(appName)")
    }
    static var undoDoneMenu: String { String(localized: "menu.undoDone", defaultValue: "Undo Done") }
    static func statusItemNow(_ title: String) -> String {
        String(localized: "statusItem.accessibility.now", defaultValue: "\(appName), Now: \(title)")
    }
    static var statusItemNothingNow: String {
        String(localized: "statusItem.accessibility.nothingNow", defaultValue: "\(appName), nothing now")
    }

    // Settings — groups
    static var menuBarSection: String {
        String(localized: "settings.section.menuBar", defaultValue: "Menu Bar")
    }
    static var keyboardSection: String {
        String(localized: "settings.section.keyboard", defaultValue: "Keyboard")
    }

    // Settings — menu bar
    static var bold: String { String(localized: "settings.menuBar.bold", defaultValue: "Bold") }
    static var color: String { String(localized: "settings.menuBar.color", defaultValue: "Color") }
    static var automatic: String {
        String(localized: "settings.menuBar.color.automatic", defaultValue: "Automatic")
    }
    static var custom: String {
        String(localized: "settings.menuBar.color.custom", defaultValue: "Custom")
    }

    // Settings — done sound
    static var playSound: String {
        String(localized: "settings.sound.play", defaultValue: "Play sound")
    }
    static var sound: String { String(localized: "settings.sound.name", defaultValue: "Sound") }
    static var defaultSoundName: String {
        String(localized: "settings.sound.defaultName", defaultValue: "Pop (default)")
    }
    static var preview: String { String(localized: "settings.sound.preview", defaultValue: "Preview") }
    static var chooseEllipsis: String {
        String(localized: "settings.sound.choose", defaultValue: "Choose…")
    }
    static var useDefault: String {
        String(localized: "settings.sound.useDefault", defaultValue: "Use Default")
    }
    static var soundTooLong: String {
        String(
            localized: "settings.sound.error.tooLong",
            defaultValue: "That sound is longer than 3 seconds."
        )
    }
    static var soundUnreadable: String {
        String(
            localized: "settings.sound.error.unreadable",
            defaultValue: "Couldn't read that sound file."
        )
    }
    /// Inline message for a custom sound that could not be installed. An unsupported file type,
    /// an unreadable file and a failed copy all read the same to the user.
    static func soundMessage(for error: any Error) -> String {
        switch error as? CustomSoundError {
        case .tooLong: soundTooLong
        case .unsupportedType, .unreadable, nil: soundUnreadable
        }
    }

    // Settings — keyboard
    static var showWedgeShortcut: String {
        String(localized: "settings.keyboard.showWedge", defaultValue: "Show Wedge")
    }
    static var reset: String { String(localized: "settings.keyboard.reset", defaultValue: "Reset") }

    // Settings — login item and about
    static var openAtLogin: String {
        String(localized: "settings.login.openAtLogin", defaultValue: "Open at login")
    }
    static var openLoginItems: String {
        String(localized: "settings.login.openLoginItems", defaultValue: "Open Login Items")
    }
    static var loginChangeFailed: String {
        String(
            localized: "settings.login.error.changeFailed",
            defaultValue: "Couldn't change this. Check System Settings › General › Login Items."
        )
    }
    static func aboutVersion(_ version: String) -> String {
        String(localized: "settings.about.version", defaultValue: "\(appName) \(version)")
    }
    static var gitHub: String { String(localized: "settings.about.gitHub", defaultValue: "GitHub") }
    /// A URL, not copy: never translated.
    static let gitHubAddress = "https://github.com/adminALEX/wedge"
}
