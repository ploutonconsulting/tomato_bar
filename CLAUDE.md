# Tiny Tomato Bar

macOS menu-bar Pomodoro timer (SwiftUI + AppKit), distributed on the Mac App Store. Internal project name: TomatoBar. Documentation vault: `Documents/vault/`.

## Commands

```bash
# Build
xcodebuild build -scheme TomatoBar -configuration Debug -destination 'platform=macOS'

# Test
xcodebuild test -scheme TomatoBar -destination 'platform=macOS' -only-testing TomatoBarTests

# Lint (autofix)
swiftlint --fix TomatoBar/

# Lint (report only)
swiftlint lint TomatoBar/
```

## Key Files

- `TomatoBar/Timer.swift` — Core timer logic, state machine, scheduling (`TBTimer`, `TBScheduleRule`)
- `TomatoBar/View.swift` — SwiftUI popover views (intervals, settings)
- `TomatoBar/State.swift` — State machine types (idle/work/rest)
- `TomatoBar/App.swift` — Entry point, menu-bar setup (`TBStatusItem`)
- `TomatoBar/Log.swift` — Structured event logging (`TBLogEvent` protocol)
- `TomatoBar/Player.swift` — Sound playback (`TBPlayer`)
- `TomatoBar/Notifications.swift` — macOS notification dispatch (`TBNotificationCenter`)
- `TomatoBarTests/TomatoBarTests.swift` — Unit tests (Swift Testing framework)

## Code Style

- `NSLocalizedString` keys follow `ViewName.property.label` convention (e.g. `SettingsView.autoStartEnabled.label`)
- All `@AppStorage` properties live on `TBTimer` — no separate settings model

## Workflow

- After editing `.swift` files → SwiftLint runs automatically (hook), then verify build with `/xcode-build-check`
- After editing `.strings` files → sync reminder fires (hook), then verify with `/localization-sync-check`
- Before committing → run both checks above

## Gotchas

- **Test target.** `TomatoBarTests` uses Swift Testing. Tests cover `TBScheduleRule`, log encoding, and notification enums. `TBTimer` is not directly testable yet (coupled to AppKit singletons in `init()`).
- **Localization sync.** Three locales (`en`, `ko`, `zh-Hans`) must stay in sync. Every key in `en.lproj/Localizable.strings` must exist in `ko.lproj` and `zh-Hans.lproj`.
- **SwiftLint config.** `.swiftlint.yml` disables `trailing_comma` and `opening_brace`. Don't re-enable or pass `--config`.
- **Never edit these files:** `TomatoBar.xcodeproj/project.pbxproj`, `TomatoBar.entitlements`, `export_options.plist` — signing-critical.
- **Fully sandboxed.** No entitlements beyond `com.apple.security.app-sandbox`.
