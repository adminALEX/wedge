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
}
