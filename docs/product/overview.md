# Wedge — Product overview

Wedge is a small macOS **menu-bar** app for working through a list one item at a time. The menu bar shows the item you are on. Everything else waits below it, in order. **Requires macOS 26 Tahoe** or later.

Wedge is free, open source and local. It has no accounts, no sync and no network access.

## Idea

The list is ordered, and position is priority. The top item is **Now**; everything below it is **Up Next**. There are no priority fields, tags or multiple lists. To change what matters, drag a row, or drag it to the top to make it Now.

Finishing the Now item is the one moment Wedge makes a fuss over. **Done** fills the ring, pops the title away, and lets the next item rise into its place. A sound plays and the menu-bar title swaps with a small bump. Nothing else in the app celebrates.

## Language

| Concept | Say |
|---------|-----|
| App | Wedge |
| The top item, shown in the menu bar | **Now** |
| Everything below it | **Up Next** |
| Finish the Now item | **Done** |
| Undo the last Done | **Undo Done** |
| Global shortcuts | **Show Wedge** · **Done** |

All three nouns are title case when used as labels. Internal code names follow the UI noun (`NowHeader`, not a name from an older phase).

**Voice:** quiet and plain, like Apple's own utilities. No praise, no emoji, no exclamation marks. Motion and sound carry the emotion. Every failure is a short inline message. There is no system beep as feedback. No OS-version caveats or developer notes appear in the UI.

**Words to avoid** in the UI, docs and code names: "one thing", OneThing, Focus, Spotlight (as a name for Wedge's own concepts), Today, On Deck, Priority, Pinned, push, pop, stack, P0/P1. "Pop" is an internal name only; the bundled sound is called **Pop (default)** in Settings and nothing else.

## Core loop

1. The menu bar shows the Now item, or the Wedge glyph when the list is empty.
2. Click it, or press ⌃⌥W, to open the panel. The add field is focused. Add, edit, reorder or delete.
3. Press **Done** (⌘↩, the ring, ⌥-click on the menu-bar item, the menu, or ⌃⌥D) when the Now item is finished. The next item rises into place, with a sound.
4. If Done was a mistake, **Undo Done** (⌘Z) restores the item to the top until the next change to the list.
5. The list is saved locally and is there after quit and restart.

### The panel

A borderless glass panel anchored under the menu-bar item, 320 pt wide. From top to bottom:

- **Now**: the ring (the Done control) and the Now item, in semibold and slightly larger than the rows.
- **Up Next**: numbered rows, 2, 3, 4… Rows drag by their whole body. The Now item is row 1 of the same list, so dragging a row to the top makes it Now (no Done animation).
- The add field, with an `n/40` counter from 30 characters.
- A hint row: `⌘↩ Done · ⌘, Settings`.

An empty list shows only the add field ("What are you on now?"). Adds go to the bottom; the first item added becomes Now. Items are limited to 40 characters. The panel does not activate Wedge or change the app's activation policy; it opens over whatever you are doing.

### Done

- Ring fills green and checks, the title swells slightly and pops out, the next row rises into the Now slot, and the menu-bar title swaps with a small bump. About 450 ms with the Done sound.
- With **Reduce Motion** on, the swap is instant and the sound still plays.
- Done is identical from every entry point. With the panel closed (or hidden) it only swaps the menu-bar title, bumps it and plays the sound. The undo hint appears only when Done happens with the panel open.
- Esc cancels an edit in progress first; only when nothing is being edited does it close the panel.

### When the list can't be saved or read

A banner at the top of the panel says what happened:

- Save failed: "Couldn't save. Your latest changes may be lost." It clears on the next successful save.
- The file was damaged: "Couldn't read your list. A copy was saved in Application Support." Wedge starts empty and keeps the damaged file as a copy. The notice clears on the next successful save.
- The file couldn't be read at all (for example it was written by a newer version): "Couldn't read your list. Changes won't be saved until Wedge can read it." Wedge starts empty and does not write until the next launch, so the original file is never overwritten.

## Shortcuts and Spotlight

Wedge provides three actions to Shortcuts and Spotlight, with no setup: **Add to Up Next**, **Mark Done** and **Get Now**. Suggested phrases are "Add to Up Next in Wedge", "Mark Done in Wedge" and "What's Now in Wedge". They run inside the Wedge process and use the same validation and Done action as the panel.

## Focused by default

Wedge stays small on purpose. After 1.0:

- Bug fixes, OS updates and polish ship freely.
- A new feature is added only by a deliberate decision, with its own short design doc, and only if it fits the core rules: **one item Now, order is priority, menu-bar only, local only.**

Still out of the product: sync, iCloud, accounts, Dock mode, confetti, priority fields, tags or multiple lists, an in-app updater, and a Mac App Store build. These are today's decisions rather than permanent bans; any of them can be reopened through the same process.

## Related

- Roadmap and history: [roadmap.md](roadmap.md)
- Design spec: [../superpowers/specs/2026-11-01-wedge-1.0-redesign-design.md](../superpowers/specs/2026-11-01-wedge-1.0-redesign-design.md)
- Agent rules: `.cursor/rules/wedge-product.mdc`, `.cursor/rules/macos-menubar.mdc`
