# Wedge — Product overview

Wedge is a minimal macOS **menu-bar** utility. It stays out of the way and keeps one clear focus visible at all times. **Requires macOS 15 Sequoia** or later.

## Idea

Like OneThing, the menu bar always shows your **one thing**. Unlike OneThing, Wedge holds an ordered list: the top item is the one thing; everything below is **Up next**. Order is priority — drag to rearrange. There are no priority fields or labels (no P0/P1 in the UI).

Finishing the current focus is the emotional core: **Done** removes the one thing (a satisfying **pop**, with sound). The next Up next item becomes the one thing.

## Language

| Concept | Say |
|---------|-----|
| App | Wedge |
| Menu bar title | the **one thing** |
| Rest of the list | **Up next** |
| Finish current focus | **Done** (feel: pop) |

Avoid in UI: push, pop, stack, P0/P1.

## Product horizon

Wedge is intentionally small. The product is planned only through **v3**:

| Phase | Role |
|-------|------|
| [v1](phases/v1.md) | Shipped — core loop, usable daily |
| [v2](phases/v2.md) | Shipped — global hotkeys, remapping, denser keyboard |
| [v3](phases/v3.md) | Shipped — Settings (pop sound on/off + custom file, launch at login) |

See [roadmap.md](roadmap.md) for the index.

**Out of product entirely:** cloud sync, iCloud, accounts, multi-device sync, Dock as a product mode, confetti, v4+ feature dumps.

## Core loop (all phases)

1. See the one thing in the menu bar (or icon only if empty).
2. Open the floating panel to add, reorder (drag grips), edit, or delete.
3. **Done** when finished — next item rises; pop + sound.
4. List persists locally across quit and reboot.
5. Optional: **Settings…** (⌘, or status-item menu) for menu-bar look.

## Related

- Phase details: [phases/v1.md](phases/v1.md), [v2.md](phases/v2.md), [v3.md](phases/v3.md)
- Agent rules: `.cursor/rules/wedge-product.mdc`
