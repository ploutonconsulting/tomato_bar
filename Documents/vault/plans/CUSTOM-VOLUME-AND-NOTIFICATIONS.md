# Custom Volume Control & Visual Notifications

**Status:** Implemented  
**Branch:** `feature/update-sounds`  
**Date:** 2026-04-17

## Problem

Timer sounds use `AudioServicesPlaySystemSound()` which plays at system volume with no override. When system volume is low or music is playing, notification sounds are inaudible and easily missed.

## Solution

Two features addressing the problem from different angles:

### 1. Custom Volume Control

- Migrated audio engine from `AudioToolbox`/`SystemSoundID` to `NSSound`
- `NSSound` supports a `.volume` property (0.0--1.0), loads the same system `.aiff` files, and is sandbox-safe
- Added "Custom volume" toggle + slider in the Sounds tab
- One volume level applies to all timer sounds (start and end)
- When disabled, sounds play at system volume (original behaviour)

**New `@AppStorage` keys:** `useCustomVolume` (Bool), `customVolumeLevel` (Double)

### 2. macOS Visual Notifications

- Added `workStarted` notification category so banners fire when work begins (previously only rest transitions had notifications)
- Added global "Show notifications" toggle in Settings tab
- Toggle guards the `send()` method -- all notification categories respect it
- Existing "Skip" action on rest-start notifications preserved

**New `@AppStorage` key:** `notificationsEnabled` (Bool)

## Files Changed

| File | Change |
|------|--------|
| `Services/Player.swift` | Migrated to NSSound, added volume properties |
| `Services/Notifications.swift` | Added workStarted category, notification toggle |
| `Core/Timer.swift` | Exposed notificationCenter, added work-start notification |
| `View.swift` | Volume slider in SoundsView, notification toggle in SettingsView |
| `en.lproj/Localizable.strings` | 5 new keys |
| `ko.lproj/Localizable.strings` | 5 new keys |
| `zh-Hans.lproj/Localizable.strings` | 5 new keys |
| `TomatoBarTests.swift` | workStarted category test, NSSound loading test |

## Design Decisions

- **NSSound over AVAudioPlayer:** Simpler, native AppKit, no extra framework import, sandbox-safe, ARC-managed (no manual dispose)
- **Single volume slider:** One volume for all sounds keeps UI simple; per-sound volume is over-engineering for 2 sounds
- **Global notification toggle:** One toggle vs per-event toggles -- keeps the small popover UI clean
- **`public let` for notificationCenter:** Mirrors existing `public let player` pattern on TBTimer
