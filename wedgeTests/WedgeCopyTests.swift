import Foundation
import Testing

@testable import wedge

@Suite("WedgeCopy")
@MainActor
struct WedgeCopyTests {
    @Test("canonical product words are non-empty and stable")
    func canonicalWords() {
        #expect(!WedgeCopy.appName.isEmpty)
        #expect(WedgeCopy.done == "Done")
        #expect(WedgeCopy.now == "Now")
        #expect(WedgeCopy.upNext == "Up Next")
        #expect(WedgeCopy.addNowPlaceholder == "What are you on now?")
        #expect(WedgeCopy.addUpNextPlaceholder == "Add to Up Next…")
        #expect(WedgeCopy.quitMenu.contains(WedgeCopy.appName))
    }

    @Test("menus, shortcut names and announcements match the spec")
    func menuAndShortcutCopy() {
        #expect(WedgeCopy.delete == "Delete")
        #expect(WedgeCopy.settingsMenu == "Settings…")
        #expect(WedgeCopy.quitMenu == "Quit Wedge")
        #expect(WedgeCopy.undoDoneMenu == "Undo Done")
        #expect(WedgeCopy.showWedgeShortcut == "Show Wedge")
        #expect(WedgeCopy.moveUp == "Move Up")
        #expect(WedgeCopy.moveDown == "Move Down")
        #expect(WedgeCopy.statusItemNow("Ship it") == "Wedge, Now: Ship it")
        #expect(WedgeCopy.statusItemNothingNow == "Wedge, nothing now")
        #expect(WedgeCopy.doneNowAnnouncement("B") == "Done. Now: B")
        #expect(WedgeCopy.doneNothingUpNextAnnouncement == "Done. Nothing up next.")
        #expect(WedgeCopy.addToUpNextTitle == "Add to Up Next")
        #expect(WedgeCopy.markDoneTitle == "Mark Done")
        #expect(WedgeCopy.getNowTitle == "Get Now")
        #expect(WedgeCopy.addedToUpNext == "Added to Up Next.")
        #expect(WedgeCopy.nothingToMarkDone == "Nothing to mark done.")
        #expect(WedgeCopy.nowIs("Ship it") == "Now: Ship it")
    }

    @Test("panel copy matches the spec")
    func panelCopy() {
        #expect(WedgeCopy.panelHint == "⌘↩ Done · ⌘, Settings")
        #expect(WedgeCopy.undoHint == "Undo Done ⌘Z")
        #expect(WedgeCopy.maxCharacters == "40 characters max")
        #expect(WedgeCopy.cantBeEmpty == "Can't be empty")
        #expect(WedgeCopy.nowAccessibility("Ship it") == "Now, Ship it")
        #expect(WedgeCopy.doneAccessibility("Ship it") == "Done, Ship it")
        #expect(WedgeCopy.rowAccessibility(2, of: 5, "Ship it") == "2 of 5, Ship it")
        #expect(WedgeCopy.movedTo(3) == "Moved to 3")
        #expect(WedgeCopy.message(for: WedgeStoreError.emptyText) == "Can't be empty")
        #expect(WedgeCopy.message(for: WedgeStoreError.textTooLong(max: 40)) == "40 characters max")
        #expect(IssueBanner.message(for: .saveFailed) == "Couldn't save. Your latest changes may be lost.")
        #expect(
            IssueBanner.message(for: .recoveredFromCorruptFile)
                == "Couldn't read your list. A copy was saved in Application Support."
        )
        #expect(
            IssueBanner.message(for: .loadFailed)
                == "Couldn't read your list. Changes won't be saved until Wedge can read it."
        )
    }

    @Test("settings copy matches the spec")
    func settingsCopy() {
        #expect(WedgeCopy.menuBarSection == "Menu Bar")
        #expect(WedgeCopy.keyboardSection == "Keyboard")
        #expect(WedgeCopy.bold == "Bold")
        #expect(WedgeCopy.color == "Color")
        #expect(WedgeCopy.automatic == "Automatic")
        #expect(WedgeCopy.custom == "Custom")
        #expect(WedgeCopy.playSound == "Play sound")
        #expect(WedgeCopy.sound == "Sound")
        #expect(WedgeCopy.defaultSoundName == "Pop (default)")
        #expect(WedgeCopy.chooseEllipsis == "Choose…")
        #expect(WedgeCopy.useDefault == "Use Default")
        #expect(WedgeCopy.reset == "Reset")
        #expect(WedgeCopy.openAtLogin == "Open at login")
        #expect(WedgeCopy.openLoginItems == "Open Login Items")
        #expect(WedgeCopy.aboutVersion("1.0") == "Wedge 1.0")
        #expect(WedgeCopy.gitHub == "GitHub")
        #expect(WedgeCopy.gitHubAddress == "https://github.com/adminALEX/wedge")
        #expect(
            WedgeCopy.loginChangeFailed
                == "Couldn't change this. Check System Settings › General › Login Items."
        )
    }

    @Test("sound errors map to the two inline messages")
    func soundErrorCopy() {
        #expect(WedgeCopy.soundMessage(for: CustomSoundError.tooLong) == "That sound is longer than 3 seconds.")
        #expect(WedgeCopy.soundMessage(for: CustomSoundError.unreadable) == "Couldn't read that sound file.")
        #expect(WedgeCopy.soundMessage(for: CustomSoundError.unsupportedType) == "Couldn't read that sound file.")
        #expect(WedgeCopy.soundMessage(for: CocoaError(.fileWriteOutOfSpace)) == "Couldn't read that sound file.")
    }

    // MARK: Guards

    /// Every `WedgeCopy` value, built here (not in production code) so a new member is a deliberate
    /// addition to this list. Functions are sampled with neutral arguments.
    private static var allStrings: [String] {
        [
            WedgeCopy.appName, WedgeCopy.done, WedgeCopy.now, WedgeCopy.upNext, WedgeCopy.delete,
            WedgeCopy.addNowPlaceholder, WedgeCopy.addUpNextPlaceholder, WedgeCopy.panelHint,
            WedgeCopy.undoHint, WedgeCopy.maxCharacters, WedgeCopy.cantBeEmpty, WedgeCopy.moveUp,
            WedgeCopy.moveDown, WedgeCopy.nowAccessibility("Ship it"), WedgeCopy.doneAccessibility("Ship it"),
            WedgeCopy.rowAccessibility(2, of: 5, "Ship it"), WedgeCopy.movedTo(3),
            WedgeCopy.message(for: WedgeStoreError.emptyText),
            WedgeCopy.message(for: WedgeStoreError.textTooLong(max: 40)),
            WedgeCopy.doneNowAnnouncement("Ship it"), WedgeCopy.doneNothingUpNextAnnouncement,
            WedgeCopy.addToUpNextTitle, WedgeCopy.markDoneTitle, WedgeCopy.getNowTitle,
            WedgeCopy.addedToUpNext, WedgeCopy.nothingToMarkDone, WedgeCopy.nowIs("Ship it"),
            WedgeCopy.saveFailed, WedgeCopy.recoveredFromCorruptFile, WedgeCopy.loadFailed,
            WedgeCopy.settingsMenu, WedgeCopy.quitMenu, WedgeCopy.undoDoneMenu,
            WedgeCopy.statusItemNow("Ship it"), WedgeCopy.statusItemNothingNow,
            WedgeCopy.menuBarSection, WedgeCopy.keyboardSection,
            WedgeCopy.bold, WedgeCopy.color, WedgeCopy.automatic, WedgeCopy.custom,
            WedgeCopy.playSound, WedgeCopy.sound, WedgeCopy.defaultSoundName, WedgeCopy.preview,
            WedgeCopy.chooseEllipsis, WedgeCopy.useDefault, WedgeCopy.soundTooLong, WedgeCopy.soundUnreadable,
            WedgeCopy.soundMessage(for: CustomSoundError.tooLong),
            WedgeCopy.soundMessage(for: CustomSoundError.unreadable),
            WedgeCopy.showWedgeShortcut, WedgeCopy.reset,
            WedgeCopy.openAtLogin, WedgeCopy.openLoginItems, WedgeCopy.loginChangeFailed,
            WedgeCopy.aboutVersion("1.0"), WedgeCopy.gitHub, WedgeCopy.gitHubAddress, WedgeCopy.checkForUpdates,
        ]
    }

    @Test("every WedgeCopy value is non-empty")
    func everyValueIsNonEmpty() {
        for value in Self.allStrings {
            #expect(!value.isEmpty)
        }
    }

    @Test("no copy echoes a competitor's name or exposes the internal sound name")
    func wordsToAvoid() {
        for value in Self.allStrings where value != WedgeCopy.defaultSoundName {
            let lowered = value.lowercased()
            #expect(!lowered.contains("one thing"), "\(value)")
            #expect(!lowered.contains("one task"), "\(value)")
            #expect(!lowered.contains("pop"), "\(value)")
        }
        #expect(WedgeCopy.defaultSoundName == "Pop (default)")
    }

    @Test("the String Catalog's English values are the defaults the code carries")
    func catalogMatchesDefaults() throws {
        let catalogURL = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "wedge/Copy/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let catalog = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(catalog["sourceLanguage"] as? String == "en")
        let strings = try #require(catalog["strings"] as? [String: [String: Any]])
        #expect(!strings.isEmpty)

        let plainValues = Set(Self.allStrings)
        for (key, entry) in strings {
            #expect(entry["extractionState"] as? String == "manual", "\(key)")
            let localizations = entry["localizations"] as? [String: [String: [String: String]]]
            let value = try #require(localizations?["en"]?["stringUnit"]?["value"], "\(key)")
            #expect(!value.isEmpty, "\(key)")
            if !value.contains("%") {
                #expect(plainValues.contains(value), "\(key): \(value)")
            }
        }
    }
}
