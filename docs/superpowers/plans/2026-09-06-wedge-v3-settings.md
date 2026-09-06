# Wedge v3 Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Settings controls for Done pop sound (on/off + optional custom file) and launch-at-login toggle.

**Architecture:** Mirror `MenuBarAppearance` with a tiny `PopSoundPreferences` UserDefaults façade. On custom Choose, copy the user-selected file into Application Support (sandbox-friendly; no bookmark management). `PopSoundPlayer` reads preferences on play/reload and posts/observes a change notification. Extend `LaunchAtLoginService` with `isEnabled` + `setEnabled(_:)`. Add two Settings sections; grow the window frame.

**Tech Stack:** SwiftUI Settings, AppKit (`NSOpenPanel`, `NSSound`), `ServiceManagement` (`SMAppService`), UserDefaults, Application Support FileManager, Swift Testing / XCTest (`wedgeTests`).

**Spec:** `docs/superpowers/specs/2026-09-06-wedge-v3-settings-design.md`  
**Product:** `docs/product/phases/v3.md`

## Global Constraints

- Pop sound: **on/off** + optional **custom file**; default bundled `pop-sound.mp3`; no preset gallery.
- When sound is **off**, Done is **fully silent** (no beep).
- Copy custom audio into Application Support — do not rely on long-lived security-scoped bookmarks.
- Launch at login: Settings toggle via `SMAppService.mainApp`; keep one-shot `enableOnLaunch()` for first run.
- Language: **one thing**, **Up next**, **Done**. No Dock/cloud/confetti.
- Ponytail: fewest files; no new SPM deps; reuse Settings Form sections.
- Do not commit `dist/` or `xcuserdata`.

---

## File map

| File | Role |
|------|------|
| `wedge/Audio/PopSoundPreferences.swift` | UserDefaults: enabled + custom filename; Application Support copy/clear helpers |
| `wedge/Audio/PopSoundPlayer.swift` | Honor enabled; load custom or bundled; reload on notify |
| `wedge/LaunchAtLogin/LaunchAtLoginService.swift` | `isEnabled`, `setEnabled(_:)` |
| `wedge/Settings/WedgeSettingsView.swift` | Sound + Login sections |
| `wedgeTests/PopSoundPreferencesTests.swift` | Preference defaults + custom path helpers (temp dir) |
| `docs/product/phases/v3.md` (+ roadmap/overview/rule) | Status when done |

---

### Task 1: PopSoundPreferences + unit tests

**Files:**
- Create: `wedge/Audio/PopSoundPreferences.swift`
- Create: `wedgeTests/PopSoundPreferencesTests.swift`

**Interfaces:**
- Consumes: `UserDefaults`, `FileManager`
- Produces:
  - `PopSoundPreferences.isEnabled: Bool` (default **true** when key absent)
  - `PopSoundPreferences.customFileName: String?`
  - `PopSoundPreferences.customSoundURL: URL?`
  - `PopSoundPreferences.installCustomSound(from: URL) throws`
  - `PopSoundPreferences.clearCustomSound()`
  - `PopSoundPreferences.applicationSupportDirectory: URL` (injectable base for tests)
  - Notification `.wedgePopSoundPreferencesDidChange`

- [ ] **Step 1: Write failing tests**

```swift
import Foundation
import Testing
@testable import wedge

@Suite
struct PopSoundPreferencesTests {
    @Test
    func enabledDefaultsToTrue() {
        let defaults = UserDefaults(suiteName: "wedge.tests.pop.\(UUID().uuidString)")!
        defer { defaults.removePersistentDomain(forName: defaults.suiteName!) }
        #expect(PopSoundPreferences.isEnabled(defaults: defaults) == true)
    }

    @Test
    func disabledPersists() {
        let defaults = UserDefaults(suiteName: "wedge.tests.pop.\(UUID().uuidString)")!
        defer { defaults.removePersistentDomain(forName: defaults.suiteName!) }
        PopSoundPreferences.setEnabled(false, defaults: defaults)
        #expect(PopSoundPreferences.isEnabled(defaults: defaults) == false)
    }

    @Test
    func installAndClearCustomSound() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("wedge-pop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let defaults = UserDefaults(suiteName: "wedge.tests.pop.\(UUID().uuidString)")!
        defer { defaults.removePersistentDomain(forName: defaults.suiteName!) }

        let source = tmp.appendingPathComponent("sample.aiff")
        // Minimal non-empty file is enough for copy path tests (player not invoked).
        try Data([0, 1, 2, 3]).write(to: source)

        try PopSoundPreferences.installCustomSound(
            from: source,
            defaults: defaults,
            supportRoot: tmp.appendingPathComponent("Support", isDirectory: true)
        )
        #expect(PopSoundPreferences.customFileName(defaults: defaults) == "custom-pop.aiff")
        #expect(PopSoundPreferences.customSoundURL(defaults: defaults, supportRoot: tmp.appendingPathComponent("Support")) != nil)

        PopSoundPreferences.clearCustomSound(
            defaults: defaults,
            supportRoot: tmp.appendingPathComponent("Support", isDirectory: true)
        )
        #expect(PopSoundPreferences.customFileName(defaults: defaults) == nil)
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcodebuild test -scheme wedge -destination 'platform=macOS' -only-testing:wedgeTests/PopSoundPreferencesTests -quiet
```

Expected: FAIL (type/module missing).

- [ ] **Step 3: Implement `PopSoundPreferences`**

```swift
import Foundation

extension Notification.Name {
    static let wedgePopSoundPreferencesDidChange = Notification.Name("wedgePopSoundPreferencesDidChange")
}

enum PopSoundPreferences {
    static let enabledKey = "wedge.popSoundEnabled"
    static let customFileNameKey = "wedge.popSoundCustomFileName"

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        if defaults.object(forKey: enabledKey) == nil { return true }
        return defaults.bool(forKey: enabledKey)
    }

    static func setEnabled(_ enabled: Bool, defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: enabledKey)
        notify()
    }

    static func customFileName(defaults: UserDefaults = .standard) -> String? {
        let name = defaults.string(forKey: customFileNameKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (name?.isEmpty == false) ? name : nil
    }

    static func defaultSupportRoot() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Wedge", isDirectory: true)
    }

    static func customSoundURL(
        defaults: UserDefaults = .standard,
        supportRoot: URL = defaultSupportRoot()
    ) -> URL? {
        guard let name = customFileName(defaults: defaults) else { return nil }
        let url = supportRoot.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Copies `source` into Application Support as `custom-pop.<ext>`.
    static func installCustomSound(
        from source: URL,
        defaults: UserDefaults = .standard,
        supportRoot: URL = defaultSupportRoot()
    ) throws {
        let ext = source.pathExtension.isEmpty ? "aiff" : source.pathExtension.lowercased()
        let allowed: Set<String> = ["aiff", "aif", "wav", "mp3", "m4a", "caf"]
        guard allowed.contains(ext) else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        try FileManager.default.createDirectory(at: supportRoot, withIntermediateDirectories: true)
        // ponytail: single slot — replace any previous custom file
        if let existing = try? FileManager.default.contentsOfDirectory(
            at: supportRoot,
            includingPropertiesForKeys: nil
        ) {
            for url in existing where url.lastPathComponent.hasPrefix("custom-pop.") {
                try? FileManager.default.removeItem(at: url)
            }
        }
        let dest = supportRoot.appendingPathComponent("custom-pop.\(ext)")
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: source, to: dest)
        defaults.set(dest.lastPathComponent, forKey: customFileNameKey)
        notify()
    }

    static func clearCustomSound(
        defaults: UserDefaults = .standard,
        supportRoot: URL = defaultSupportRoot()
    ) {
        if let name = customFileName(defaults: defaults) {
            let url = supportRoot.appendingPathComponent(name)
            try? FileManager.default.removeItem(at: url)
        }
        defaults.removeObject(forKey: customFileNameKey)
        notify()
    }

    static func notify() {
        NotificationCenter.default.post(name: .wedgePopSoundPreferencesDidChange, object: nil)
    }
}
```

If `CocoaError(.fileReadUnsupportedScheme)` feels wrong for “bad extension”, use a tiny `enum PopSoundPreferencesError: Error { case unsupportedType }` instead — keep one error type only.

- [ ] **Step 4: Run tests — expect PASS**

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcodebuild test -scheme wedge -destination 'platform=macOS' -only-testing:wedgeTests -quiet
```

Expected: all PASS (including new suite).

- [ ] **Step 5: Commit**

```bash
git add wedge/Audio/PopSoundPreferences.swift wedgeTests/PopSoundPreferencesTests.swift
git commit -m "$(cat <<'EOF'
feat: persist pop sound on/off and custom file prefs.

EOF
)"
```

---

### Task 2: PopSoundPlayer honors preferences

**Files:**
- Modify: `wedge/Audio/PopSoundPlayer.swift`
- Modify: `wedge/StatusItem/StatusItemController.swift` (only if player needs explicit reload hook — prefer player self-observes)

**Interfaces:**
- Consumes: `PopSoundPreferences.isEnabled`, `customSoundURL`, `.wedgePopSoundPreferencesDidChange`
- Produces: `play()` no-ops when disabled; otherwise custom or bundled; `NSSound.beep()` only if enabled but load/play fails

- [ ] **Step 1: Replace player body**

```swift
import AppKit

/// Plays the Done confirmation sound (bundled default or custom).
@MainActor
final class PopSoundPlayer {
    private var sound: NSSound?
    private var observer: NSObjectProtocol?

    init() {
        reload()
        observer = NotificationCenter.default.addObserver(
            forName: .wedgePopSoundPreferencesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reload()
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func play() {
        guard PopSoundPreferences.isEnabled() else { return }
        guard let sound else {
            NSSound.beep()
            return
        }
        sound.stop()
        if !sound.play() {
            NSSound.beep()
        }
    }

    func reload() {
        sound?.stop()
        if let custom = PopSoundPreferences.customSoundURL() {
            sound = NSSound(contentsOf: custom, byReference: false)
        } else {
            sound = Self.loadBundledSound()
        }
    }

    private static func loadBundledSound() -> NSSound? {
        guard let url = Bundle.main.url(forResource: "pop-sound", withExtension: "mp3") else {
            return nil
        }
        return NSSound(contentsOf: url, byReference: false)
    }
}
```

- [ ] **Step 2: Build**

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcodebuild build -scheme wedge -destination 'platform=macOS' -quiet
```

Expected: **BUILD SUCCEEDED**.

- [ ] **Step 3: Manual smoke (optional mid-flight)**

With defaults, Done still plays bundled sound.

- [ ] **Step 4: Commit**

```bash
git add wedge/Audio/PopSoundPlayer.swift
git commit -m "$(cat <<'EOF'
feat: play custom or bundled pop sound when enabled.

EOF
)"
```

---

### Task 3: LaunchAtLoginService toggle API

**Files:**
- Modify: `wedge/LaunchAtLogin/LaunchAtLoginService.swift`
- Test: none for SMAppService (no seam without mocking framework) — verify compile + manual smoke in Task 4

**Interfaces:**
- Consumes: `SMAppService.mainApp`
- Produces: `static var isEnabled: Bool`, `static func setEnabled(_ enabled: Bool) throws`  
  Keep existing `enableOnLaunch(defaults:)`.

- [ ] **Step 1: Extend service**

```swift
static var isEnabled: Bool {
    SMAppService.mainApp.status == .enabled
}

static func setEnabled(_ enabled: Bool) throws {
    let service = SMAppService.mainApp
    if enabled {
        guard service.status != .enabled else { return }
        try service.register()
    } else {
        guard service.status != .notRegistered else { return }
        // Also handle .enabled / .requiresApproval — unregister when not already off
        try service.unregister()
    }
}
```

Treat `.requiresApproval` as not enabled for the toggle’s `get`; if `register()` leaves approval pending, Settings should re-read status after toggle (Task 4).

- [ ] **Step 2: Build**

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcodebuild build -scheme wedge -destination 'platform=macOS' -quiet
```

Expected: **BUILD SUCCEEDED**.

- [ ] **Step 3: Commit**

```bash
git add wedge/LaunchAtLogin/LaunchAtLoginService.swift
git commit -m "$(cat <<'EOF'
feat: expose launch-at-login enable and disable for Settings.

EOF
)"
```

---

### Task 4: Settings UI — Sound + Login

**Files:**
- Modify: `wedge/Settings/WedgeSettingsView.swift`

**Interfaces:**
- Consumes: `PopSoundPreferences`, `PopSoundPlayer` (local preview instance), `LaunchAtLoginService`, `NSOpenPanel`
- Produces: Form sections **Sound** and **General** (or **Startup**)

- [ ] **Step 1: Add state + sections**

Extend `WedgeSettingsView` (keep appearance + shortcuts). Add:

```swift
@State private var soundEnabled = PopSoundPreferences.isEnabled()
@State private var customName = PopSoundPreferences.customFileName()
@State private var launchAtLogin = LaunchAtLoginService.isEnabled
@State private var previewPlayer = PopSoundPlayer()
```

In the `Form`, after appearance (or after shortcuts — order: Appearance, Sound, Startup, Keyboard shortcuts is fine):

```swift
Section {
    Toggle("Play sound", isOn: $soundEnabled)
    HStack {
        Text(customName.map { "Custom: \($0)" } ?? "Default pop sound")
            .foregroundStyle(.secondary)
            .lineLimit(1)
        Spacer()
        Button("Preview") { previewPlayer.play() }
            .disabled(!soundEnabled)
        Button("Choose…") { chooseCustomSound() }
        if customName != nil {
            Button("Use default") {
                PopSoundPreferences.clearCustomSound()
                customName = nil
            }
        }
    }
} header: {
    Text("Sound")
} footer: {
    Text("Played when you mark Done. Choose a short AIFF, WAV, MP3, M4A, or CAF file.")
        .foregroundStyle(.secondary)
}

Section {
    Toggle("Launch at login", isOn: $launchAtLogin)
} header: {
    Text("General")
} footer: {
    Text("Starts Wedge automatically when you log in to your Mac.")
        .foregroundStyle(.secondary)
}
```

Wire:

```swift
.onChange(of: soundEnabled) { _, on in
    PopSoundPreferences.setEnabled(on)
}
.onChange(of: launchAtLogin) { _, on in
    do {
        try LaunchAtLoginService.setEnabled(on)
    } catch {
        NSSound.beep()
    }
    launchAtLogin = LaunchAtLoginService.isEnabled
}
```

Choose helper:

```swift
private func chooseCustomSound() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff, .mpeg4Audio]
    // If some UTTypes are unavailable, fall back to `panel.allowedFileTypes = ["aiff","wav","mp3","m4a","caf"]` (deprecated but fine) or only `.audio`.
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
        try PopSoundPreferences.installCustomSound(from: url)
        customName = PopSoundPreferences.customFileName()
    } catch {
        NSSound.beep()
    }
}
```

Import `UniformTypeIdentifiers` if using `UTType`.

Increase frame height (e.g. base ~420 / with color ~460) so new sections fit.

- [ ] **Step 2: Build + full unit tests**

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
xcodebuild test -scheme wedge -destination 'platform=macOS' -only-testing:wedgeTests -quiet
```

Expected: PASS.

- [ ] **Step 3: Manual smoke**

1. Settings → Play sound off → Done silent.  
2. On + Preview → hear default.  
3. Choose custom short sound → Preview + Done use it; quit/relaunch still custom.  
4. Use default → bundled again.  
5. Launch at login toggle ↔ System Settings → General → Login Items.

- [ ] **Step 4: Commit**

```bash
git add wedge/Settings/WedgeSettingsView.swift
git commit -m "$(cat <<'EOF'
feat: Settings for pop sound and launch at login.

EOF
)"
```

---

### Task 5: Docs — v3 status

**Files:**
- Modify: `docs/product/phases/v3.md`
- Modify: `docs/product/roadmap.md`
- Modify: `docs/product/overview.md`
- Modify: `.cursor/rules/wedge-product.mdc`

**Interfaces:**
- Consumes: Tasks 1–4 shipped behavior
- Produces: aligned product docs (Implemented — pending acceptance, or Shipped after human smoke)

- [ ] **Step 1: Update phase/roadmap/rule**

Set v3 status to **Implemented — pending manual acceptance** (or **Shipped** only after full smoke). Document: on/off + custom file + login toggle. Point product rule **Next** at done / maintenance once shipped.

- [ ] **Step 2: Commit**

```bash
git add docs/product/phases/v3.md docs/product/roadmap.md docs/product/overview.md .cursor/rules/wedge-product.mdc
git commit -m "$(cat <<'EOF'
docs: record v3 settings control implementation status.

EOF
)"
```

---

## Spec coverage (self-review)

| Spec requirement | Task |
|------------------|------|
| Sound on/off (default on; silent when off) | 1–2, 4 |
| Custom file via Choose + Use default | 1, 4 |
| Copy into Application Support | 1 |
| Preview | 4 |
| Player reload on change | 2 |
| Login toggle register/unregister | 3–4 |
| Keep enableOnLaunch one-shot | 3 (unchanged API) |
| Docs | 5 |

## Placeholder scan

No TBD steps; concrete code and commands included.

## Type consistency

- Keys: `wedge.popSoundEnabled`, `wedge.popSoundCustomFileName`
- Notification: `.wedgePopSoundPreferencesDidChange`
- Service: `LaunchAtLoginService.isEnabled` / `setEnabled(_:)`

---

Plan complete and saved to `docs/superpowers/plans/2026-09-06-wedge-v3-settings.md`. Spec: `docs/superpowers/specs/2026-09-06-wedge-v3-settings-design.md`. Product `phases/v3.md` updated for on/off + custom file.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task  
2. **Inline Execution** — this session with checkpoints  

Which approach?
