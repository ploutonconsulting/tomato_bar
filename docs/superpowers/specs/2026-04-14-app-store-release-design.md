# Tiny Tomato Bar — App Store Release Design

## Summary

Rebrand TomatoBar fork for Mac App Store distribution as "Tiny Tomato Bar". Replace buddhabeats-licensed sounds with macOS system sounds, remove ticking feature, update legal attribution, and prepare metadata for App Store submission.

## Context

- TomatoBar is an MIT-licensed macOS Pomodoro timer by Ilya Voronin
- Pierre's fork adds auto-start/stop scheduling and localization (en, ko, zh-Hans)
- The fork will be published on the Mac App Store as "Tiny Tomato Bar" under bundle ID `com.ploutonconsulting.veridian`
- Apple ID: `6762198642`, SKU: `cb474462-e573-467a-9048-8a3596eccd16`
- Internal project names (folder, target, scheme) remain `TomatoBar`

## Changes

### 1. Display Name

Update `INFOPLIST_KEY_CFBundleDisplayName` from `Veridian` to `Tiny Tomato Bar` in both Debug and Release build settings in `project.pbxproj`.

### 2. Sounds — Replace Bundled Audio with System Sounds

**Remove ticking entirely:**
- Delete `TomatoBar/Assets.xcassets/ticking.dataset/` (directory + contents)
- Remove from `Player.swift`: `tickingSound` property, `tickingVolume` @AppStorage, `startTicking()`, `stopTicking()`, and all ticking init/setup code
- Remove from `View.swift`: ticking volume slider and its label
- Remove from all 3 `Localizable.strings`: `SoundsView.isTickingEnabled.label` key
- Remove from `Timer.swift`: all calls to `player.startTicking()` and `player.stopTicking()`

**Replace windup and ding with system sounds:**
- Delete `TomatoBar/Assets.xcassets/windup.dataset/` and `TomatoBar/Assets.xcassets/ding.dataset/`
- Rewrite `Player.swift` to use `NSSound(named:)` instead of `AVAudioPlayer` + `NSDataAsset`:
  - `windup` → `NSSound(named: "Purr")`
  - `ding` → `NSSound(named: "Glass")`
- `NSSound` supports volume via the `volume` property (0.0–1.0), so volume controls remain functional
- Remove `import AVFoundation` (no longer needed)

### 3. Legal Attribution

**NSHumanReadableCopyright** (in `project.pbxproj`, both Debug and Release):
- Change from: `"Copyright © 2023 Ilya Voronin. All rights reserved. https://github.com/ivoronin/TomatoBar"`
- Change to: `"Copyright © 2022 Ilya Voronin, 2026 Pierre Oosthuizen. MIT License. https://github.com/ivoronin/TomatoBar"`

**Info.plist — URL scheme:**
- Change `CFBundleURLName` from `com.github.ivoronin.TomatoBar` to `com.ploutonconsulting.veridian`
- Change `CFBundleURLSchemes` from `tomatobar` to `veridian`

**LICENSE file:** No changes (already lists both copyright holders).

### 4. README.md

Rewrite to reflect the fork:
- Title: "Tiny Tomato Bar"
- Description: macOS menu-bar Pomodoro timer, available on the Mac App Store
- Attribution: "Based on TomatoBar by Ilya Voronin" with link to upstream repo
- Installation: Mac App Store link (placeholder until published) + Homebrew removal note
- Remove upstream GitHub badges
- Keep screenshot reference (update path if needed)

### 5. CI Workflow

**`.github/workflows/main.yml`:**
- Update ZIP artifact name from `TomatoBar-${{env.version}}.zip` to `TinyTomatoBar-${{env.version}}.zip`
- Scheme and project names stay `TomatoBar` (internal names unchanged)

### 6. Log Filename

No change — `TomatoBar.log` is internal and not user-facing.

### 7. Documentation Updates

**CLAUDE.md:** Update first line to mention "Tiny Tomato Bar" as the user-facing name.

**Documents/vault/:**
- `PROJECT.md`: Update mission statement to reference "Tiny Tomato Bar" and App Store distribution
- `LEGAL.md`: Update copyright string to match the new NSHumanReadableCopyright
- `TOOLS.md`: No changes needed (references internal names)
- `DECISIONS.md`: Add ADR for App Store rebrand and sound replacement

## Files Modified

| File | Change |
|------|--------|
| `TomatoBar.xcodeproj/project.pbxproj` | Display name, copyright string |
| `TomatoBar/Info.plist` | URL scheme |
| `TomatoBar/Player.swift` | Rewrite: NSSound system sounds, remove ticking |
| `TomatoBar/Timer.swift` | Remove ticking calls |
| `TomatoBar/View.swift` | Remove ticking UI |
| `TomatoBar/en.lproj/Localizable.strings` | Remove ticking key |
| `TomatoBar/ko.lproj/Localizable.strings` | Remove ticking key |
| `TomatoBar/zh-Hans.lproj/Localizable.strings` | Remove ticking key |
| `README.md` | Rewrite for fork |
| `.github/workflows/main.yml` | Artifact name |
| `CLAUDE.md` | User-facing name |
| `Documents/vault/PROJECT.md` | Mission, milestones |
| `Documents/vault/LEGAL.md` | Copyright string |
| `Documents/vault/DECISIONS.md` | New ADR |

## Files Deleted

| File | Reason |
|------|--------|
| `TomatoBar/Assets.xcassets/windup.dataset/*` | Buddhabeats-licensed audio |
| `TomatoBar/Assets.xcassets/ding.dataset/*` | Buddhabeats-licensed audio |
| `TomatoBar/Assets.xcassets/ticking.dataset/*` | Buddhabeats-licensed audio + feature removed |

## Out of Scope

- App icon changes (keeping current tomato icon, MIT-licensed)
- Xcode target/scheme/folder rename (staying as TomatoBar internally)
- App Store screenshots and marketing materials
- App Store submission itself (just preparing the code)
