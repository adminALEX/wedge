---
name: wedge-keep-aligned
description: >-
  Align Wedge plans, docs, and .cursor rules after a product confirmation,
  scope change, feature decision, or completed implementation phase.
  Use when the user confirms product changes, asks to update the plan/roadmap,
  or finishes a phase/feature that should be reflected in docs.
---

# Wedge keep aligned

## When to run

- User confirms or changes product decisions (scope, interactions, language).
- A feature or fix ships and plans/docs should reflect reality.
- User says “align docs”, “update the plan”, “sync rules”, or similar.

## Workflow

1. **Diff the decision** — What changed vs `.cursor/rules/wedge-product.mdc` and any files under `docs/`?
2. **Rules first** — If language, scope (in/out), or core interactions changed, patch `.cursor/rules/` immediately (keep rules minimal).
3. **Roadmap** — Update `docs/product/roadmap.md` (current 1.0 and "Post-1.0 candidates"). `docs/product/history/` is an archive of earlier phases and is not updated. Use `roadmap-update` when helpful.
4. **Implementation plan** — If build steps changed and a plan exists, update it (or use `writing-plans`). Prefer `docs/superpowers/plans/` or `docs/plans/`.
5. **Docs** — Keep `docs/product/overview.md` consistent; use `docs-updater` when syncing after landed code changes.
6. **Report** — List files touched and any remaining mismatches.

## Do not

- Add a feature, or cloud/sync/Dock-mode, without a deliberate decision and its own short design doc that fits the core rules (one item Now, order is priority, menu-bar only, local only). See "Focused by default" in `docs/product/overview.md`. List a post-1.0 candidate in the roadmap only after that decision.
- Put truncation or char limits other than **40** into the product without confirmation.
- Leave rules contradicting the latest confirmation.
