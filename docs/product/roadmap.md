# Wedge — Roadmap

**Current: Wedge 1.0** — requires macOS 26 Tahoe. See [overview.md](overview.md) for the product and the design spec at [../superpowers/specs/2026-11-01-wedge-1.0-redesign-design.md](../superpowers/specs/2026-11-01-wedge-1.0-redesign-design.md) for how it is built.

Wedge 1.0 supersedes the earlier "v1 to v3 only" horizon. The earlier phases remain as history and are the requirements baseline that 1.0 kept.

## 1.0

| Area | Summary |
|------|---------|
| Panel | Borderless, non-activating glass panel anchored under the menu-bar item; Now and Up Next in one list; drag a row to the top to make it Now |
| Done | Ring, pop, rise and menu-bar bump with sound; Undo Done (⌘Z) |
| Settings | One page: Menu Bar, Done sound, Keyboard, Open at login |
| Keyboard | Global ⌃⌥W (Show Wedge) and ⌃⌥D (Done), both remappable; full in-panel keys |
| Shortcuts | App Intents: Add to Up Next, Mark Done, Get Now (Shortcuts and Spotlight) |
| Storage | Versioned JSON file with atomic writes; recovery from a damaged or unreadable file |
| Privacy | No analytics, no background network access. The only connection is the on-click update check to GitHub Releases. Verifiable from the sandbox entitlements and privacy manifest |
| Distribution | Developer ID–signed, notarized download on GitHub Releases. No Mac App Store. Check for Updates in Settings installs new releases (Sparkle, on click only) |

## History

Earlier phases, kept for reference:

| Phase | Summary | Doc |
|-------|---------|-----|
| v1 | Core menu-bar list and panel, Settings, open at login, 40-character cap | [history/v1.md](history/v1.md) · [plan](../superpowers/plans/2026-08-16-wedge-v1.md) |
| v2 | Global hotkeys with remapping, denser panel keyboard | [history/v2.md](history/v2.md) · [plan](../superpowers/plans/2026-09-06-wedge-v2-hotkeys.md) |
| v3 | Settings: Done sound on/off and custom file, open at login | [history/v3.md](history/v3.md) · [plan](../superpowers/plans/2026-09-06-wedge-v3-settings.md) |

These documents use the language of their time and are not updated.

## Post-1.0 candidates

_None._

New features follow the process in [overview.md](overview.md#focused-by-default): a deliberate decision, a short design doc of its own, and a fit with the core rules. A candidate is listed here only once that decision has been made.

## Not planned

Sync, iCloud, accounts, Dock mode, confetti, priority fields, tags or multiple lists, an in-app updater, a Mac App Store build, and truncation of long titles (the 40-character cap stays).

## Change policy

- Keep this file, [overview.md](overview.md) and `.cursor/rules/wedge-product.mdc` aligned when scope is confirmed or changed.
- Do not add a feature to this file without the process above.
