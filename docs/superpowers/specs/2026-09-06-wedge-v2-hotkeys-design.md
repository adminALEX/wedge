# Wedge v2 — Global hotkeys + panel keyboard (design)

**Date:** 2026-09-06  
**Status:** Approved for planning (defaults A + Settings remapping)  
**Product:** [`docs/product/phases/v2.md`](../../product/phases/v2.md)

## Goal

Power users toggle the panel and mark Done from anywhere, remap those two chords in Settings, and drive the open panel with denser keyboard (↑/↓, ⌫, ⌘↩).

## Defaults

| Action | Default chord |
|--------|----------------|
| Toggle panel | ⌃⌥W |
| Done | ⌃⌥D |

No global “focus add field” hotkey (panel open already focuses add).

## Approach (ponytail)

Use **sindresorhus/KeyboardShortcuts** (SPM): name registration + persistence + SwiftUI `Recorder` + `reset`. Do not hand-roll Carbon or a custom recorder.

Wire handlers in `StatusItemController.start()` to existing `togglePanel()` / `performDone()`.

Settings: one **Hotkeys** section — two recorders + **Reset to defaults**.

Panel keyboard: restore `List(selection:)` for native ↑/↓ and ⌫ (`onDeleteCommand`), keep **tap-to-edit** (`Text` → `TextField`) so selection does not fight always-on row fields. ⌘↩ Done unchanged.

## Non-goals

Sound picker, login toggle, extra hotkeys, Dock, cloud — see v2/v3 phase docs.

## Risks

- Library docs discourage shipping hard-coded `initial:` shortcuts for public apps; **Wedge v2 product requires defaults** — intentional.
- Remapping conflicts: rely on KeyboardShortcuts’ built-in conflict warning. Prefer remaps that include **Control or Command** (Apple Forums: Option/Shift-only hotkeys were restricted for sandboxed apps on macOS 15.0–15.1; Control+Option defaults are always valid).
- Secure Input (password fields): global hotkeys do not fire — expected OS behavior.
- Do not use `NSEvent.addGlobalMonitorForEvents` — requires Accessibility; Wedge is sandboxed.

## Success

- ⌃⌥W / ⌃⌥D work system-wide after launch; remaps persist; Reset restores defaults.
- Panel: select with arrows, ⌫ deletes selected when not editing, edit still works via tap.
- Docs/checklist updated when implemented.
