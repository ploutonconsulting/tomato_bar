---
title: TomatoBar — Tools
version: 1.2
created: 2026-04-14
updated: 2026-04-14
tags:
  - tomatobar
  - tools
---

# TomatoBar — Tools & Automation

## Frameworks & Libraries

| Tool | Purpose |
|------|---------|
| SwiftUI | UI framework for popover views |
| AppKit | Menu-bar integration (NSStatusItem, NSPopover) |
| SwiftState | Finite state machine for timer transitions |
| KeyboardShortcuts | Global hotkey registration |
| LaunchAtLogin | Launch-at-login preference management |

## Claude Skills Used

| Skill | Purpose |
|-------|---------|
| xcode-build-check | Build TomatoBar and report compile errors concisely |
| swiftlint-autofix | Run SwiftLint --fix on Swift files, report residual violations |
| localization-sync-check | Verify localization key parity across en, ko, zh-Hans |

## Claude Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| SwiftLint autofix | PostToolUse (Edit/Write on .swift) | Auto-fix lint violations on save |
| Localization sync warning | PostToolUse (Edit/Write on .strings) | Remind to sync all 3 locales |

## Testing

- **Framework:** Swift Testing (`import Testing`)
- **Target:** `TomatoBarTests`
- **Run:** `xcodebuild test -scheme TomatoBar -destination 'platform=macOS' -only-testing TomatoBarTests`
- **Coverage:** `TBScheduleRule`, log event encoding, notification enums, system sound file existence

## Build

```bash
xcodebuild build -scheme TomatoBar -configuration Debug -destination 'platform=macOS'
```

- Debug configuration only for development (avoids code-signing issues)
- Build log written to `/tmp/tomatobar-build.log` by the xcode-build-check skill

## Linting

- **Config:** `.swiftlint.yml` at repo root
- **Disabled rules:** `trailing_comma`, `opening_brace`
- **Run:** `swiftlint` at repo root (picks up config automatically)
- The PostToolUse hook runs `swiftlint --fix` automatically on every Swift file edit

## Localization

- **Locales:** `en`, `ko`, `zh-Hans`
- **Files:** `TomatoBar/{en,ko,zh-Hans}.lproj/Localizable.strings`
- All keys must stay in sync across all three locales
- The PostToolUse hook warns when a `.strings` file is edited

## Scripts & Automation

| Script | Location | Purpose |
|--------|----------|---------|
| GitHub Actions | `.github/workflows/main.yml` | CI build |
| Export options | `export_options.plist` | Xcode archive export configuration |

## Vault Index

| Document | Purpose |
|----------|---------|
| [[ARCHITECTURE]] | System design, components, data models |
| [[DECISIONS]] | Architecture Decision Records |
| [[DOMAIN]] | Business domain, personas, glossary |
| [[PROJECT]] | Risks, issues, tasks, milestones |
| [[UI-DESIGN]] | Design system, screens, UX flows, brand |
| [[LOGGING]] | Logging strategy and rules |
| [[TOOLS]] | This document |
| [[LEGAL]] | Copyright, licences |

---

## Related Documents

- [[PROJECT]] — Project context
- [[ARCHITECTURE]] — Technical environment
