# Wedge v2 Hotkeys Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship system-wide Toggle panel (⌃⌥W) and Done (⌃⌥D), remappable in Settings, plus denser panel keyboard (↑/↓ select, ⌫ delete, ⌘↩ Done).

**Architecture:** Add sindresorhus `KeyboardShortcuts` via SPM (Carbon `RegisterEventHotKey`, sandbox-safe). One tiny `WedgeHotkeys.swift` holds `KeyboardShortcuts.Name` defaults. `StatusItemController.start()` registers **`onKeyDown`** handlers that call existing `togglePanel` / `performDone`. Settings gains a **Keyboard shortcuts** section with two `Recorder`s + reset. Panel restores `List(selection:)` for native arrow/delete while keeping tap-to-edit rows.

**Tech Stack:** SwiftUI, AppKit (`StatusItemController`), KeyboardShortcuts SPM 3.x, XCTest / Swift Testing (`wedgeTests`), Xcode project `wedge`.
**Spec:** `docs/superpowers/specs/2026-09-06-wedge-v2-hotkeys-design.md`  
**Product:** `docs/product/phases/v2.md`

## Global Constraints

- Defaults exactly **⌃⌥W** (toggle) and **⌃⌥D** (Done); no third global hotkey.
- Remapping lives in native Settings (v2); sound/login stay v3.
- Language: **one thing**, **Up next**, **Done** — not push/pop/stack/P0.
- Menu-bar only; floating panel; 40-char hard limit unchanged.
- Ponytail: fewest new files; no custom Carbon/recorder; no Accessibility wizard unless smoke proves KeyboardShortcuts is insufficient.
- App is **sandboxed** (`ENABLE_APP_SANDBOX = YES`) + `LSUIElement` — use Carbon-backed shortcuts (KeyboardShortcuts), **not** `NSEvent.addGlobalMonitorForEvents` (needs Accessibility / Input Monitoring).
- Do not commit `dist/`.

---

## Verification (Apple docs + platform practice)

Checked against Apple Developer Forums (RegisterEventHotKey / Sequoia), Apple “Settings scene” docs, KeyboardShortcuts (sandbox/MAS), and Wedge’s existing panel patterns.

| Topic | Verdict | Plan impact |
|-------|---------|-------------|
| **API choice** | Prefer `RegisterEventHotKey` (via KeyboardShortcuts) over `NSEvent` global monitors — no Accessibility prompt; works sandboxed + MAS. | Keep SPM approach (**A**). Do **not** add TCC/Accessibility UI in v2. |
| **Defaults ⌃⌥W / ⌃⌥D** | Sequoia briefly required a modifier beyond Option/Shift alone for sandboxed hotkeys (Apple Forums thread 763878; eased in 15.2). **Control+Option** always satisfied that rule. | Keep defaults. In Settings footer, warn that remaps should include **Control or Command** (not Option/Shift only) for widest macOS 15.x compatibility; rely on KeyboardShortcuts’ built-in conflict / Option dialog. |
| **Settings placement** | Apple: macOS apps expose settings via SwiftUI `Settings` scene / App menu Settings… | Hotkeys section in existing `WedgeSettingsView` is correct. Prefer section title **Keyboard shortcuts** (System Settings wording) over “Hotkeys”. |
| **Key up vs key down** | AppKit menu equivalents fire on key **down**; Carbon hotkey callbacks are press-oriented. | Use `KeyboardShortcuts.onKeyDown` (not `onKeyUp`) for toggle + Done. |
| **Secure Input** | Global hotkeys do not fire while Secure Input is on (password fields, some auth UI). | Document in smoke — expected OS behavior, not a Wedge bug. |
| **Panel keyboard** | Native `List(selection:)` + `onDeleteCommand` matches AppKit list keyboard; prior bug was **always-on** row `TextField` + selection. | Keep tap-to-edit + selection. ⌫ deletes **selection only** when not editing / add-focused (let text fields own ⌫). |
| **Package** | Pin a major line (3.x) when adding SPM so resolves are reproducible. | Task 1: add from `https://github.com/sindresorhus/KeyboardShortcuts` with Up to Next Major from **3.0.0** (or current 3.x). |

**Ponytail call:** Still do **not** hand-roll Carbon. Library already is the Apple-compatible path.

---

## File map

| File | Role |
|------|------|
| `wedge/Hotkeys/WedgeHotkeys.swift` | `KeyboardShortcuts.Name` for `.togglePanel` / `.markDone` with `initial:` defaults |
| `wedge/StatusItem/StatusItemController.swift` | Register `onKeyUp` in `start()` |
| `wedge/Settings/WedgeSettingsView.swift` | Hotkeys section: recorders + reset; taller frame |
| `wedge/Views/PopoverContentView.swift` | Restore `List(selection:)`; keep tap-to-edit |
| `wedge.xcodeproj/project.pbxproj` | SPM dependency on KeyboardShortcuts |
| `docs/product/phases/v2.md` (+ roadmap/overview/rule if status changes) | Mark progress / acceptance notes when done |

---

### Task 1: Add KeyboardShortcuts + name defaults

**Files:**
- Create: `wedge/Hotkeys/WedgeHotkeys.swift`
- Modify: `wedge.xcodeproj/project.pbxproj` (via Xcode SPM UI or equivalent)
- Test: none (package + compile gate)

**Interfaces:**
- Consumes: none
- Produces: `KeyboardShortcuts.Name.togglePanel`, `KeyboardShortcuts.Name.markDone` with initials ⌃⌥W / ⌃⌥D

- [ ] **Step 1: Add the SPM package to the wedge app target**

In Xcode: File → Add Package Dependencies → URL `https://github.com/sindresorhus/KeyboardShortcuts` → **Up to Next Major Version** from `3.0.0` (or current 3.x) → add product **KeyboardShortcuts** to target **wedge**.

Or from repo root, if using `xcodebuild` after manual pbxproj edit, resolve with:

```bash
xcodebuild -resolvePackageDependencies -project wedge.xcodeproj -scheme wedge
```

Confirm `Package.resolved` pins a **3.x** revision (sandbox-safe Carbon `RegisterEventHotKey` path — not `NSEvent` global monitors).
- [ ] **Step 2: Create `wedge/Hotkeys/WedgeHotkeys.swift`**

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // ponytail: product-required defaults (library prefers empty initials for public apps)
    static let togglePanel = Self(
        "togglePanel",
        initial: .init(.w, modifiers: [.control, .option])
    )
    static let markDone = Self(
        "markDone",
        initial: .init(.d, modifiers: [.control, .option])
    )
}
```

Ensure the file is in the **wedge** target (Xcode group `Hotkeys` or drag into project).

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme wedge -destination 'platform=macOS' -quiet
```

Expected: **BUILD SUCCEEDED** (no missing-module errors).

- [ ] **Step 4: Commit**

```bash
git add wedge/Hotkeys/WedgeHotkeys.swift wedge.xcodeproj/project.pbxproj wedge.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
git commit -m "$(cat <<'EOF'
chore: add KeyboardShortcuts with ⌃⌥W / ⌃⌥D defaults.

EOF
)"
```

(Include `Package.resolved` if Xcode created it.)

---

### Task 2: Wire global hotkeys to the status item controller

**Files:**
- Modify: `wedge/StatusItem/StatusItemController.swift`
- Test: manual (system-wide; no unit seam)

**Interfaces:**
- Consumes: `KeyboardShortcuts.Name.togglePanel`, `.markDone`; existing `togglePanel()`, `performDone()`
- Produces: system-wide key-down → same behavior as status-item toggle / Done

- [ ] **Step 1: Import and register handlers at end of `start()`**

In `StatusItemController.swift`:

```swift
import KeyboardShortcuts
```

At the end of `start()`, after existing observers:

```swift
// Key-down matches AppKit menu shortcut timing; Carbon hotkeys are press-oriented.
KeyboardShortcuts.onKeyDown(for: .togglePanel) { [weak self] in
    Task { @MainActor in
        self?.togglePanel()
    }
}
KeyboardShortcuts.onKeyDown(for: .markDone) { [weak self] in
    Task { @MainActor in
        self?.performDone()
    }
}
```

Do **not** duplicate Done logic — `performDone()` already no-ops when there is no one thing.

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme wedge -destination 'platform=macOS' -quiet
```

Expected: **BUILD SUCCEEDED**.

- [ ] **Step 3: Manual smoke (local)**

1. Run the app from Xcode.
2. From another app, press **⌃⌥W** — panel toggles.
3. With a one thing present, press **⌃⌥D** — item completes + pop sound.
4. With empty list, **⌃⌥D** — no crash, no sound.
5. Optional: focus a password field in another app and press the chords — no fire while Secure Input is on (expected OS behavior).
- [ ] **Step 4: Commit**

```bash
git add wedge/StatusItem/StatusItemController.swift
git commit -m "$(cat <<'EOF'
feat: register global hotkeys for toggle panel and Done.

EOF
)"
```

---

### Task 3: Settings — Hotkeys section + reset

**Files:**
- Modify: `wedge/Settings/WedgeSettingsView.swift`
- Test: manual

**Interfaces:**
- Consumes: `KeyboardShortcuts.Recorder`, `KeyboardShortcuts.reset(_:_:)`
- Produces: remappable chords persisted by the library; Reset restores initials

- [ ] **Step 1: Extend `WedgeSettingsView`**

Replace the body `Form` content with appearance + hotkeys (keep existing appearance bindings/onChange). Full file target shape:

```swift
import SwiftUI
import AppKit
import KeyboardShortcuts

struct WedgeSettingsView: View {
    @State private var isBold = MenuBarAppearance.isBold
    @State private var usesAutomaticColor = MenuBarAppearance.usesAutomaticColor
    @State private var customColor = Color(
        nsColor: MenuBarAppearance.customTitleColor ?? .labelColor
    )

    var body: some View {
        Form {
            Section {
                Toggle("Bold", isOn: $isBold)
                Toggle("Automatic color", isOn: $usesAutomaticColor)
                if !usesAutomaticColor {
                    ColorPicker("Color", selection: $customColor, supportsOpacity: false)
                }
            } footer: {
                Text("Applies to the one thing in the menu bar. Automatic follows the system label color.")
                    .foregroundStyle(.secondary)
            }

            Section {
                KeyboardShortcuts.Recorder("Toggle panel", name: .togglePanel)
                KeyboardShortcuts.Recorder("Done", name: .markDone)
                Button("Reset to defaults") {
                    KeyboardShortcuts.reset(.togglePanel, .markDone)
                }
            } header: {
                Text("Keyboard shortcuts")
            } footer: {
                Text("Defaults are ⌃⌥W (toggle panel) and ⌃⌥D (Done). Prefer chords that include Control or Command — Option/Shift-only remaps can fail on some macOS 15 versions. Remapping saves automatically.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: usesAutomaticColor ? 280 : 320)
        .onChange(of: isBold) { _, newValue in
            MenuBarAppearance.isBold = newValue
        }
        .onChange(of: usesAutomaticColor) { _, automatic in
            if automatic {
                MenuBarAppearance.colorHex = ""
            } else {
                MenuBarAppearance.colorHex = NSColor(customColor).wedgeHex
            }
        }
        .onChange(of: customColor) { _, newValue in
            guard !usesAutomaticColor else { return }
            MenuBarAppearance.colorHex = NSColor(newValue).wedgeHex
        }
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme wedge -destination 'platform=macOS' -quiet
```

Expected: **BUILD SUCCEEDED**.

- [ ] **Step 3: Manual smoke**

1. Open Settings (⌘, with panel open, or status-item **Settings…**).
2. Change Done to another unused chord; quit and relaunch — remap sticks.
3. **Reset to defaults** — chords show ⌃⌥W / ⌃⌥D again and work.

- [ ] **Step 4: Commit**

```bash
git add wedge/Settings/WedgeSettingsView.swift
git commit -m "$(cat <<'EOF'
feat: remappable global hotkeys in Settings.

EOF
)"
```

---

### Task 4: Panel keyboard — restore list selection (keep tap-to-edit)

**Files:**
- Modify: `wedge/Views/PopoverContentView.swift`
- Test: manual (selection + edit coexistence)

**Interfaces:**
- Consumes: existing `editingItemID` / `PanelFocus` / `ItemRow` tap-to-edit
- Produces: `List(selection:)` for ↑/↓ and ⌫ via `onDeleteCommand`; edit still tap-to-TextField

- [ ] **Step 1: Add selection state and wire `List(selection:)`**

In `PopoverContentView`:

1. Add `@State private var selection: UUID?` (keep `editingItemID` and `focus`).
2. Change `list` to:

```swift
private var list: some View {
    List(selection: $selection) {
        ForEach(store.items) { item in
            itemRow(item)
                .tag(item.id)
                .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
        }
        .onMove { indices, newOffset in
            store.move(from: indices, to: newOffset)
            onChange()
        }
        .onDelete { indexSet in
            let ids = indexSet.map { store.items[$0].id }
            ids.forEach { store.delete(id: $0) }
            if let editingItemID, ids.contains(editingItemID) {
                self.editingItemID = nil
            }
            if let selection, ids.contains(selection) {
                self.selection = nil
            }
            onChange()
        }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .frame(maxHeight: .infinity)
    .onDeleteCommand { deleteSelectedItem() }
}```

3. Replace `deleteFocusedItem()` with selection-only delete (text fields keep ⌫ while editing):

```swift
private func deleteSelectedItem() {
    // ponytail: List selection owns ⌫; TextFields own ⌫ while focused
    guard editingItemID == nil, focus != .add else { return }
    guard let id = selection else { return }
    store.delete(id: id)
    selection = nil
    onChange()
}
```

Wire `.onDeleteCommand { deleteSelectedItem() }`.

4. In context-menu Delete, also clear `selection` when it matches the deleted id.
5. In `focusAddField()`, set `selection = nil`.

Do **not** remove tap-to-edit `ItemRow` (`Text` / `TextField` swap).
- [ ] **Step 2: Build + unit tests still green**

```bash
xcodebuild test -scheme wedge -destination 'platform=macOS' -only-testing:wedgeTests -quiet
```

Expected: all existing store tests **PASS**.

- [ ] **Step 3: Manual smoke**

1. Open panel; click a row’s grip/background so the row is selected (blue).
2. ↑/↓ moves selection.
3. ⌫ deletes selected row when **not** editing.
4. Click row **text** — edit mode works; type; Return commits.
5. While editing text, ⌫ deletes characters (not the row).
6. ⌘↩ still Done; drag via grip still reorders.

- [ ] **Step 4: Commit**

```bash
git add wedge/Views/PopoverContentView.swift
git commit -m "$(cat <<'EOF'
feat: restore list selection for denser panel keyboard.

EOF
)"
```

---

### Task 5: Docs — mark v2 implemented / acceptance notes

**Files:**
- Modify: `docs/product/phases/v2.md`
- Modify: `docs/product/roadmap.md`
- Modify: `docs/product/overview.md` (status line if needed)
- Modify: `.cursor/rules/wedge-product.mdc` (v2 shipped vs next)

**Interfaces:**
- Consumes: shipped behavior from Tasks 1–4
- Produces: aligned product docs

- [ ] **Step 1: Update `docs/product/phases/v2.md`**

Set status to **Implemented — pending manual acceptance** (or **Shipped** only if you completed the full human smoke in Task 2–4). Add a short acceptance table mirroring v1 style: global toggle, global Done, remap + reset, panel ↑/↓/⌫, ⌘↩.

- [ ] **Step 2: Align roadmap / overview / product rule**

- Roadmap v2 row status matches the phase doc.
- If v2 is only “pending acceptance”, keep v3 Planned; product rule **Next** can stay v2 until acceptance, then point at v3.

- [ ] **Step 3: Commit**

```bash
git add docs/product/phases/v2.md docs/product/roadmap.md docs/product/overview.md .cursor/rules/wedge-product.mdc
git commit -m "$(cat <<'EOF'
docs: record v2 hotkeys implementation status.

EOF
)"
```

---

## Spec coverage (self-review)

| Spec requirement | Task |
|------------------|------|
| ⌃⌥W toggle / ⌃⌥D Done defaults | 1 |
| System-wide handlers → existing paths | 2 (`onKeyDown`) |
| Settings remappers + Reset | 3 |
| Panel ↑/↓, ⌫, ⌘↩; edit still works | 4 |
| Docs alignment | 5 |
| No sound/login/extra hotkeys | Out of scope (not tasked) |

## Placeholder scan

No TBD/TODO steps; concrete code and commands included.

## Type consistency

- Names: `.togglePanel`, `.markDone` everywhere.
- Controllers: `togglePanel()`, `performDone()` unchanged signatures.
- Selection: `UUID?` tagged with `item.id`.

---

Plan complete and saved to `docs/superpowers/plans/2026-09-06-wedge-v2-hotkeys.md`. Spec: `docs/superpowers/specs/2026-09-06-wedge-v2-hotkeys-design.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — run tasks in this session with checkpoints  

Which approach?
