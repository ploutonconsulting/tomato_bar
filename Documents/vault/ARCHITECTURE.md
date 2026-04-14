---
title: TomatoBar — Architecture
version: 1.0
created: 2026-04-14
updated: 2026-04-14
tags:
  - tomatobar
  - architecture
---

# TomatoBar — Architecture

## Overview

TomatoBar is a macOS menu-bar app built with SwiftUI and AppKit interop. It implements the Pomodoro Technique with a state-machine-driven timer that cycles through idle, work, and rest states. The app is fully sandboxed with no entitlements.

## Components

### TBApp (App.swift)
Entry point. Configures the `NSApplicationDelegateAdaptor` for menu-bar integration via `TBStatusItem`. Initialises LaunchAtLogin migration and logging.

### TBTimer (Timer.swift)
Core timer logic. An `ObservableObject` that manages:
- Work/rest interval cycling via a `SwiftState` state machine
- `@AppStorage`-backed preferences (interval lengths, scheduling rules)
- Auto-start and auto-stop scheduling via `TBScheduleRule`
- Notification dispatch and sound playback triggers

### TBScheduleRule (Timer.swift)
Pure value type that determines whether a scheduled action (auto-start/auto-stop) should fire based on time-of-day and weekday bitmask. Kept free of `TBTimer` state for testability.

### Views (View.swift)
SwiftUI views for the popover settings UI:
- `IntervalsView` — work/rest interval steppers
- `SettingsView` — scheduling toggles, sound selection, global hotkey
- `TBPopoverView` — main popover layout with timer display and controls

### State Machine (State.swift)
Defines `TBStateMachineStates` (idle, work, rest) and `TBStateMachineEvents` (startStop, timerFired, skipRest).

### Player (Player.swift)
Sound playback for timer events.

### Notifications (Notifications.swift)
macOS notification dispatch for timer state transitions.

### Logging (Log.swift)
Structured event logging.

## Data Models

### Preferences
All preferences are stored via `@AppStorage` (UserDefaults). Key properties:
- Interval lengths (work, short rest, long rest)
- Work intervals per set
- Auto-start/auto-stop: enabled flag, minutes-since-midnight, weekday bitmask

### State Machine
Three states (`idle`, `work`, `rest`) with three events (`startStop`, `timerFired`, `skipRest`). Transitions are configured in `TBTimer` with guards and handlers.

## Integrations

- **SwiftState** — finite state machine library
- **KeyboardShortcuts** — global hotkey registration
- **LaunchAtLogin** — launch-at-login preference

## Deployment

- **Distribution:** GitHub Releases + Homebrew Cask (`brew install --cask tomatobar`)
- **CI:** GitHub Actions (`main.yml`)
- **Signing:** Export options via `export_options.plist`
- **Build:** Xcode / xcodebuild, Debug configuration for development

---

## Related Documents

- [[PROJECT]] — Risks, tasks, milestones
- [[DECISIONS]] — Architecture Decision Records
- [[DOMAIN]] — Business domain and glossary
- [[TOOLS]] — Tools and frameworks
