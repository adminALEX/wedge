# Wedge — Phased roadmap

Product horizon: **v1 → v2 → v3 only**. No v4. No cloud/sync.

Plans and rules must stay aligned with this file and the phase docs when scope is confirmed or changed (`wedge-keep-aligned`).

| Phase | Status | Summary | Doc |
|-------|--------|---------|-----|
| **v1** | Shipped | Core menu-bar Wedge + panel, Settings, launch at login + 40-char limit | [phases/v1.md](phases/v1.md) · [implementation plan](../superpowers/plans/2026-08-16-wedge-v1.md) (historical) |
| **v2** | Planned (next) | Global hotkeys (⌃⌥W / ⌃⌥D defaults) + remapping in Settings + denser panel keyboard | [phases/v2.md](phases/v2.md) |
| **v3** | Planned | Expand Settings: sound, login control | [phases/v3.md](phases/v3.md) |

## Explicit non-goals (all phases)

- iCloud / any cloud sync / accounts
- Dock icon as a supported product mode
- Confetti or noisy celebration UI
- “Add as one thing” mode (adds always go to bottom of Up next)
- Truncation systems in **v1** (hard 40-char cap instead)

## Change policy

- v1 path may shift slightly during implementation; update [phases/v1.md](phases/v1.md) and `.cursor/rules/` together.
- Truncation and higher character limits are **not** designed yet — discuss before adding to a phase (likely after v1).
- Do not invent v4 or sync features.

## Overview

[overview.md](overview.md)
