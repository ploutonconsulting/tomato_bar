---
title: TomatoBar — UI Design
version: 1.0
created: 2026-04-14
updated: 2026-04-14
tags:
  - tomatobar
  - ui-design
---

# TomatoBar — UI Design

## Brand

- **App icon:** Tomato-shaped icon in macOS app icon style
- **Menu bar icons:** Minimal line-art icons for each state (idle, work, short rest, long rest)
- **Typography:** System font; monospaced digit font for timer display

## Design System

- **Framework:** SwiftUI with AppKit interop for menu-bar integration
- **Layout:** NSPopover-based settings panel attached to the menu-bar icon
- **Controls:** Native macOS controls (Stepper, Toggle, DatePicker, Picker)

## Component Library

| Component | Purpose |
|-----------|---------|
| IntervalsView | Steppers for work, short rest, long rest intervals and work set size |
| SettingsView | Toggles and controls for scheduling, sounds, hotkey, stop-after-break |
| TBPopoverView | Main popover with timer display, start/stop button, settings tabs |
| TBStatusItem | NSApplicationDelegate managing the menu-bar icon and popover lifecycle |

## Screen Inventory

| Screen | Purpose | Notes |
|--------|---------|-------|
| Menu bar icon | Timer state indicator + countdown | Monospaced digit font for timer text |
| Popover — Timer | Current timer display, start/stop, skip rest | Primary interaction surface |
| Popover — Intervals | Configure work/rest durations | Stepper-based input |
| Popover — Settings | Scheduling, sounds, hotkey, launch-at-login | Toggle + conditional controls pattern |

## User Flows

### Start a Pomodoro
1. Click menu-bar icon to open popover
2. Click "Start" button
3. Icon changes to work state, countdown begins
4. Notification fires when work interval ends
5. Rest interval begins automatically

### Configure auto-start
1. Open popover → Settings tab
2. Toggle "Auto-start timer" on
3. Set start time via DatePicker
4. Select active weekdays

## Accessibility

- Uses native macOS controls (inherits VoiceOver support)
- Menu-bar icon includes accessibility label for state
- Keyboard shortcut (global hotkey) for start/stop

---

## Related Documents

- [[DOMAIN]] — User personas and context
- [[ARCHITECTURE]] — Technical constraints on UI
