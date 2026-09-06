# Wedge v3 — Settings control (design)

**Date:** 2026-09-06  
**Status:** Approved for planning (pop: on/off + custom file; login toggle)  
**Product:** [`docs/product/phases/v3.md`](../../product/phases/v3.md)

## Goal

Give users control over Done sound and launch-at-login in the existing Settings scene — no new windows, no sound preset gallery.

## Pop sound

| Control | Behavior |
|---------|----------|
| **Play sound** toggle | Default **on**. When off, Done is silent (no `NSSound.beep` fallback). |
| **Custom sound** | Optional. Default = bundled `Sounds/pop-sound.mp3`. |
| **Choose…** | `NSOpenPanel` for audio files (aiff/wav/mp3/m4a/caf). |
| **Use default** | Clears custom; back to bundled. |
| **Preview** | Plays current effective sound once. |

**Persistence (ponytail, sandbox-safe):** On Choose, copy the selected file into Application Support (`…/Wedge/custom-pop.<ext>`). Store only the relative filename / “has custom” flag in UserDefaults. Avoid security-scoped bookmark lifetime. App already has `ENABLE_USER_SELECTED_FILES = readonly` for the open panel.

**Reload:** `PopSoundPlayer` reloads when preferences change (notification), so Settings preview and Done stay in sync.

## Launch at login

| Control | Behavior |
|---------|----------|
| **Launch at login** toggle | Reflects `SMAppService.mainApp.status == .enabled`. On → `register()`, Off → `unregister()`. |

Keep v1 `enableOnLaunch()` one-shot first-run register so existing installs stay enabled; Settings toggle is the ongoing control. Surface register/unregister errors with a beep + leave toggle reflecting actual status.

## Non-goals

Dock mode, cloud, confetti, hotkey remapping (v2), multi-preset sound library, sound volume slider.

## Success

- Toggle off → Done silent; toggle on → default or custom plays.
- Custom file survives quit; Use default restores bundled.
- Login toggle matches System Settings Login Items after toggle.
- Docs mark v3 implemented when shipped.
