# Wedge agent tooling

## Installed skills (project)

| Skill | Role |
|-------|------|
| `swiftui-expert-skill` | SwiftUI / macOS UI |
| `swift-testing-expert` | Tests |
| `swift-concurrency` | Concurrency / `@Observable` |
| `writing-plans` | Bite-sized implementation plans |
| `roadmap-update` | Product roadmap and scope |
| `docs-updater` | Sync docs after landed changes |
| `wedge-keep-aligned` | Keep rules + plans + docs consistent after confirmations |

Canonical copies live in `.agents/skills/`; Cursor sees them via `.cursor/skills/` symlinks.

## Rules

- `wedge-product.mdc` — Wedge 1.0 product rules, language, behaviour, "Focused by default"
- `macos-menubar.mdc` — menu-bar Swift conventions
- `docs-plans-align.mdc` — when to update plans/docs/rules
- `find-skills-first.mdc` — always search find-skills for request-relevant skills

## Product docs

- `docs/product/overview.md`
- `docs/product/roadmap.md`
- `docs/product/history/v1.md` · `v2.md` · `v3.md` — archive of earlier phases, not updated

## Hooks

- `stop` — prompt to run `wedge-keep-aligned` after product confirmations
- `postToolUse` (Shell) — after `git commit`, remind alignment when rules/docs/code warrant it
