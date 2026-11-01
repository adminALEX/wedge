# Wedge 1.0 release checklist

Filled in by hand on the release machine. The "Measured" and "Status" columns are intentionally empty: nothing here has been measured or ticked yet. Spec references are to `docs/superpowers/specs/2026-11-01-wedge-1.0-redesign-design.md`.

Release build: ______ (version) · Date: ______ · macOS: ______ · Mac: ______

## 1. Build, notarize, publish

Needs your Developer ID certificate and a notarytool keychain profile. Nothing in the repo holds either.

- [ ] One-time: store notary credentials with `xcrun notarytool store-credentials <profile-name>`.
- [ ] Merge `redesign/wedge-1.0` and confirm CI is green on the merge commit.
- [ ] Run the script on the merged branch:
  ```bash
  WEDGE_TEAM_ID=<team-id> WEDGE_NOTARY_PROFILE=<profile-name> scripts/release.sh 1.0.0
  ```
  It archives, exports with Developer ID, notarizes, staples, re-zips and prints the SHA-256. Output lands in `build/release/1.0.0/`.
- [ ] The notary result in `build/release/1.0.0/notary-result.json` says `Accepted`.
- [ ] `spctl -a -t exec -vv build/release/1.0.0/export/wedge.app` reports `accepted` with source `Notarized Developer ID`.
- [ ] `xcrun stapler validate build/release/1.0.0/export/wedge.app` succeeds.
- [ ] Settings > About shows the expected version. The project's `MARKETING_VERSION` is `1.0`; the script does not override it, so the tag `v1.0.0` and the About row differ by design unless you change the build setting.
- [ ] Tag `v1.0.0` on the merged branch and push the tag.
- [ ] Create the GitHub Release for `v1.0.0` with `Wedge-1.0.0.zip` attached and the SHA-256 in the notes.
- [ ] Confirm `https://github.com/adminALEX/wedge/releases` is the intended public Releases location (README links to it).

SHA-256 of `Wedge-1.0.0.zip`: ______

## 2. Performance budgets (spec §7)

Measure on the notarized build, Apple silicon, with Instruments and Activity Monitor.

| Metric | Budget | How to measure | Measured | Status |
|---|---|---|---|---|
| Idle CPU | 0%, no timers or polling | Activity Monitor, Wedge idle for 60 s, panel closed | | |
| Idle memory | ≤ 50 MB resident | Activity Monitor, Memory column, after launch and after opening the panel once | | |
| Click to panel visible | Within one frame | `PanelOpen` signpost in Instruments (os_signpost) | | |
| Done animation | No dropped frames at 120 Hz | Instruments SwiftUI template; Done via ring, ⌘↩, ⌥-click, hotkey and three rapid hotkey presses | | |
| Sound latency | No audible delay after Done | By ear, built-in and custom sound | | |
| Launch to menu-bar item | < 300 ms | Launch from Finder with Wedge quit; time to the item appearing | | |

## 3. Manual acceptance (spec §8)

Run on the notarized build, using a fresh macOS user account.

| Check | Status |
|---|---|
| Panel anchors correctly on 2+ displays, menu bar on each | |
| Works over full-screen apps and across Spaces | |
| State and hotkeys survive sleep/wake and reboot | |
| Light, dark, Reduce Motion, Reduce Transparency, Increase Contrast | |
| VoiceOver reads ring, rows, reorder actions | |
| Hotkeys fire with other apps focused | |
| Open at login matches System Settings | |
| Notarized build launches cleanly on a fresh user account | |
| Second launch opens the panel of the running instance | |
| Item hidden (notch / Menu Bar settings): relaunch and hotkey still open the panel | |
| VoiceOver announces Done and moves | |
| Shortcuts app, Spotlight and Siri run all three actions, with Wedge running and not running | |
| Full Keyboard Access reaches every control | |
| Performance budgets met (§7) | |

## 4. Hands-on checks from implementation

Collected from Tasks 5 to 14. None of these could be run during development (no Mac with a GUI), so each is unverified until ticked. Each line ends with what good looks like.

### Panel and keyboard

- [ ] Click the menu-bar item: the panel appears under it, centred, with no Dock icon, and takes typing. Good: it closes on Esc and on an outside click.
- [ ] Click another menu-bar extra (Control Center, Wi-Fi) and a window of another app while the panel is open. Good: the panel closes each time.
- [ ] Click the status item while the panel is open. Good: it closes without flashing closed-then-open, and the item is highlighted exactly while the panel is visible, including after Esc and outside click.
- [ ] Toggle with the hotkey and open the panel fresh several times, including the very first open after launch. Good: the add field has a caret without clicking, every time.
- [ ] Panel position on a second display and with the item near the right screen edge. Good: centred under the item, clamped fully on screen, menu bar correct on each display.
- [ ] Choose Settings… from the right-click menu before the panel was ever opened. Good: Settings opens in front, and Wedge does not stay in the Dock.
- [ ] Walk the spec §6 keyboard table: ↑/↓ select (↑ from the add field selects the last Up Next row, ↓ from the last row returns to the add field); ↩ edits the selected row; ⌘↩ marks Done from anywhere including while editing; ⌫ deletes the selected row (not while editing) and selects the next; ⌥⌘↑/⌥⌘↓ move the row (⌥⌘↑ on row 2 makes it Now); ⌘, opens Settings; Esc closes the panel only when no edit is open. Good: every key does exactly that, and focus never gets stuck.
- [ ] Esc while editing a row (Now or Up Next). Good: the edit is cancelled, nothing is saved and the panel stays open. Clicking outside while editing saves the edit.
- [ ] Click a row title. Good: the in-place editor gets a caret, typing edits, ↩ saves and focus returns to the list.
- [ ] Add, edit, reorder (⌥⌘↑), Done (⌘↩) and Undo (⌘Z) once each by hand. Good: all work; ⌘Z undoes typing while a field has unsaved typing, otherwise restores the Done item to Now.
- [ ] Press ⌘Z after adding a trailing space to a row's text and pressing ↩ right after a Done. Good: Undo Done is still offered.
- [ ] Drag an Up Next row to the very top, then drag Now down into Up Next. Good: the row becomes Now, the old Now becomes row 2, numbers update, and the "Up Next" label row cannot be dragged or selected. Rows drag by their whole body while a click on the text still edits.
- [ ] Delete the last remaining row with ⌫, or mark the only item Done with ⌘↩. Good: focus lands in the add field.
- [ ] Input limits. Good: typing stops at 40 characters with "40 characters max"; pasting 41+ is refused with the same message; the counter appears at 30 ("30/40"); an emoji counts as one character; editing a row to empty or spaces shows "Can't be empty" and restores the old text.
- [ ] Placeholder text. Good: "What are you on now?" when the list is empty, "Add to Up Next…" otherwise.
- [ ] Add and delete rows with the panel open. Good: the panel resizes with its top edge fixed under the item; the list scrolls from 9 Up Next rows and not at 8, with no extra space or cut-off from the Now and label rows; 3 rows give a sensible height.
- [ ] Panel look in light and dark, and with Reduce Transparency on. Good: Liquid Glass, 320 pt wide, 20 pt corners, readable in every mode.
- [ ] Full Keyboard Access on, then Tab through the panel. Good: the add field and an open edit field show an accent outline, and every control is reachable.
- [ ] VoiceOver. Good: rows read "‹n› of ‹count›, ‹title›" with Move Up / Move Down actions; ring reads "Done, ‹title›"; Now reads "Now, ‹title›"; the panel reads "Wedge"; moves announce "Moved to ‹n›"; the status item reads "Wedge, Now: ‹title›" or "Wedge, nothing now".
- [ ] Force a save failure (for example a read-only Application Support folder). Good: the banner "Couldn't save. Your latest changes may be lost." appears at the top.
- [ ] Hotkeys ⌃⌥W (show) and ⌃⌥D (Done). Good: both work with other apps focused, stop firing while the right-click menu is open and work again after it closes.
- [ ] Mark Done from the hotkey, ⌘↩ in the panel, the menu and ⌥-click. Good: the menu-bar title updates each time; ⌥-click on an empty list opens the panel; "Undo Done" is in the right-click menu only right after a Done.
- [ ] Launch a second copy (`open -n` on the app) while Wedge runs, and relaunch from Finder. Good: the first copy's panel opens, the second exits, and a second item never appears in the menu bar.
- [ ] Run `xcodebuild test` locally while Wedge is running. Good: the test host is not terminated.
- [ ] Launch with `-WedgeUITest`. Good: three seeded items appear and the login item is not registered.
- [ ] Status item position. Good: it keeps its place after ⌘-drag and relaunch.

### Done moment

- [ ] Instruments SwiftUI template: Done via the ring, ⌘↩, ⌥-click, hotkey, and three rapid hotkey presses on a 120 Hz display. Good: no hitch over 8 ms.
- [ ] Watch a Done with the panel open. Good: the ring goes green with a checkmark bounce; the title swells and pops in place, lined up with the Now row; the next row rises into the Now slot (it is a list row move, not a free-flying title, so judge whether that looks right); rows below shift up; the add field and hint row do not jump or clip while the panel shrinks.
- [ ] After Done, look at the hint row. Good: "Undo Done ⌘Z" shows at the trailing end for about 4 s and disappears at once after ⌘Z or any other change to the list.
- [ ] Menu-bar title on Done, including when the title width changes and with the panel closed. Good: it swaps, then bumps around its centre, settling in about 300 ms.
- [ ] Mark Done with the hotkey while the panel is closed, then open the panel within 0.5 s and again after a few seconds. Good: neither open shows a pop or the undo hint.
- [ ] Reduce Motion on. Good: the swap is instant everywhere, with no bump.
- [ ] ⌘↩ on a selected Now row, then ↩ and ⌫. Good: they act on the new Now row.

### Settings

- [ ] Settings window. Good: title reads "Wedge Settings", width 420, height sensible with nothing clipped.
- [ ] Each control against the menu bar: Bold, Automatic/Custom with the color picker, preview of Now title versus glyph. Good: the menu-bar title and the preview update live, including as you type or complete items.
- [ ] Sound row with a custom file. Good: the name truncates in the middle, and Preview, Choose… and Use Default are all visible; Preview is disabled when Play sound is off; choosing and removing a custom sound changes the Done sound.
- [ ] Choose a file longer than 3 s, then a corrupt file, then a valid one. Good: "That sound is longer than 3 seconds.", then "Couldn't read that sound file.", then the message clears.
- [ ] Open at login on and off, and with approval pending (disable Wedge in System Settings > Login Items). Good: the message and "Open Login Items" button appear and clear after re-approving and returning to the app.
- [ ] Shortcut recorders and Reset. Good: Reset restores Control-Option-W and Control-Option-D.
- [ ] GitHub link and About row. Good: the link opens https://github.com/adminALEX/wedge and About shows "Wedge 1.0".

### Shortcuts and Spotlight

- [ ] In the Shortcuts app and Spotlight, with Wedge running and again with it quit (macOS launches it in the background). Good: Add to Up Next, Mark Done and Get Now appear under Wedge, and the phrases "Add to Up Next in Wedge", "Mark Done in Wedge" and "What's Now in Wedge" work.
- [ ] Add with empty text and with 41 characters. Good: "Can't be empty" and "40 characters max".
- [ ] Mark Done from an intent. Good: the sound plays and the menu-bar title bumps.
- [ ] Run an intent with Wedge quit, with Console showing debug level and category "done". Good: the first run launches Wedge in the background and logs "Resolving intent dependency" for the store and for the Done action.

### Icon and glyph

- [ ] Open `wedge/AppIcon.icon` in Icon Composer. Good: default, dark and tinted previews all read as a graphite background, a smoky wedge behind, and a bright white bar in front.
- [ ] Icon in Finder, in Login Items and in the Settings About row. Good: crisp and recognisable at each size.
- [ ] Menu-bar glyph at 16 pt in light and dark menu bars and while highlighted. Good: legible and correctly tinted in all three; the Settings preview with the glyph style matches.

### CI and repo

- [ ] Delete the 25 leftover `ci/*` diagnostic branches on GitHub (origin). Good: `git ls-remote --heads origin 'ci/*'` prints nothing.
- [ ] Add `docs/images/panel.png`, which the README references. Good: the README renders the screenshot on GitHub.
- [ ] Optional: start the CI workflow by hand (workflow_dispatch) from the Actions tab. Good: the UI tests step runs and passes.
