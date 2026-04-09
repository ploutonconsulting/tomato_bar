# Design Spec: Pause for Lunch

**Date:** 2026-04-09
**Branch:** `feature/schedule-updates`
**Status:** Approved — ready for implementation

---

## 1. Context

The `feature/schedule-updates` branch already introduced:
- `TBScheduleRule` — fires a one-shot auto-start or auto-stop at a configured time on selected weekdays
- `.claude/` automations — SwiftLint autofix and localization sync-check skills

This spec adds a complementary feature: a daily **lunch pause** that suppresses the pomodoro loop during a configured time window and then auto-resumes via the existing auto-start scheduler when the window ends.

---

## 2. Requirements from Clarification

### 2.1 What happens when lunch starts mid-pomodoro?

**Decision B — wait for the current session to end.** The in-progress work session runs to its natural end. Rest follows normally. At the end of rest, the transition to work is blocked — the state machine routes `rest => idle` instead of `rest => work`. No interruption of active focus time.

### 2.2 What happens at the end of the lunch window?

**Decision A — auto-resume via the auto-start scheduler.** If `autoStartEnabled` is on and today is an allowed weekday, a fresh work session kicks off automatically when the lunch window closes. No separate resume timer is needed.

### 2.3 Which days does lunch apply to?

**Decision A — reuse `autoStartDays` bitmask.** Lunch is governed by the same weekday rule as auto-start. There is no separate day picker for lunch.

### 2.4 How is duration entered?

**Decision A — `Stepper` in minutes (15–180, step 5).** Matches the `IntervalsView` styling used for work and rest interval durations.

---

## 3. Design Decision: Approach

Three approaches were considered:

| Approach | Summary | Rejected because |
|---|---|---|
| 1 | Merge lunch fields into `TBScheduleRule` | Muddies "fire once" vs "suppress window" semantics |
| **2** | **New `TBLunchWindow` value type alongside `TBScheduleRule`** | **Chosen — clean separation of concerns** |
| 3 | Add fields directly on `TBTimer` | Breaks the value-type pattern just established for auto-stop |

`TBLunchWindow` is a pure value type that answers one question: "is _now_ inside the lunch window on an allowed day?" `TBScheduleRule` asks a different question: "should I fire a one-shot action at this moment?" Keeping them separate preserves single responsibility.

---

## 4. Data Model

### 4.1 `TBLunchWindow` value type

Add to `TomatoBar/Timer.swift`, above `TBTimer`:

```swift
struct TBLunchWindow {
    let enabled: Bool
    let startMinutesSinceMidnight: Int   // 0–1439
    let durationMinutes: Int             // length of the pause
    let daysBitmask: Int                 // reuses autoStartDays

    /// Returns true when `now` is within the window on an allowed weekday.
    func contains(now: Date, calendar: Calendar = .current) -> Bool

    /// Returns the end-of-lunch Date on the same day as `now`,
    /// or nil if today's weekday is not in `daysBitmask`.
    func endDate(onSameDayAs now: Date, calendar: Calendar = .current) -> Date?
}
```

Both methods are pure functions with no side effects.

### 4.2 New `@AppStorage` keys on `TBTimer`

| Key | Type | Default | Meaning |
|---|---|---|---|
| `lunchPauseEnabled` | `Bool` | `false` | Master toggle |
| `lunchStartMinutesSinceMidnight` | `Int` | `720` (12:00 PM) | Window start time |
| `lunchDurationMinutes` | `Int` | `60` | Window length |

No existing `UserDefaults` keys are modified — fully backward compatible.

### 4.3 Computed helpers on `TBTimer`

- `lunchWindow: TBLunchWindow` — assembles the value type from `@AppStorage` fields plus `autoStartDays`.
- `lunchStartTime: Date` — `DatePicker` binding that delegates to the existing `Self.date(fromMinutes:)` and `Self.minutes(from:defaultHour:)` static helpers (default hour 12).

---

## 5. Scheduler Behaviour

### 5.1 State machine changes

Only two existing route conditions change. The `work => rest` route is **unchanged**, enforcing the "don't interrupt the current pomodoro" rule.

**Before:**
```swift
stateMachine.addRoutes(event: .timerFired, transitions: [.rest => .idle]) { _ in
    self.stopAfterBreak
}
stateMachine.addRoutes(event: .timerFired, transitions: [.rest => .work]) { _ in
    !self.stopAfterBreak
}
```

**After:**
```swift
stateMachine.addRoutes(event: .timerFired, transitions: [.rest => .idle]) { _ in
    self.stopAfterBreak || self.lunchWindow.contains(now: Date())
}
stateMachine.addRoutes(event: .timerFired, transitions: [.rest => .work]) { _ in
    !self.stopAfterBreak && !self.lunchWindow.contains(now: Date())
}
```

No new states or events are introduced.

### 5.2 `checkSchedule()` changes

Three targeted changes, nothing else:

1. **Dedup reset at lunch end** — at the top of each tick, if `lastAutoStartDate` was recorded before today's lunch-end AND `now >= lunchEnd`, clear `lastAutoStartDate`. This is what makes auto-resume possible.
2. **Auto-start guard** — the existing auto-start block gains `!lunchWindow.contains(now:)` so it cannot fire inside the window.
3. **Auto-stop** — unchanged.

### 5.3 Canonical weekday walkthrough

Settings: auto-start 09:00, auto-stop 17:00, weekdays Mon–Fri, lunch 12:00–13:00.

| Time | Event | State before | State after | Notes |
|---|---|---|---|---|
| 09:00 | `checkSchedule` tick | idle | work | Auto-start fires; `lastAutoStartDate = 09:00` |
| 11:55 | `timerFired` | rest | work | New work session starts, 5 min before lunch |
| 12:00 | Lunch window opens | work | work | No interruption |
| 12:20 | `timerFired` | work | rest | Natural end of work session |
| 12:25 | `timerFired` | rest | idle | Lunch guard: `rest => idle` instead of `rest => work` |
| 12:25–13:00 | `checkSchedule` ticks | idle | idle | Auto-start blocked by lunch guard |
| 13:00 | `checkSchedule` tick | idle | idle | Dedup clear: `lastAutoStart (09:00) < lunchEnd (13:00)` and `now >= 13:00` |
| 13:00+30s | `checkSchedule` tick | idle | work | Auto-start fires again |
| 17:00 | `checkSchedule` tick | work/rest | idle | Auto-stop fires normally |

### 5.4 Edge cases

1. **Manual loop without auto-start** — state machine guard still applies; loop pauses at `rest => idle`. No auto-resume (auto-start is off). User restarts manually. Graceful degradation.
2. **Lunch straddles midnight** — out of scope. `contains` evaluates weekday from the `startMinutesSinceMidnight` anchor; windows crossing midnight always return false.
3. **Duration 0 or ≥ 1440** — prevented at the UI layer by Stepper range 15...180.
4. **Auto-start time inside the lunch window** — blocked in the morning; dedup-clear at window end allows auto-start to fire once the window closes.
5. **Device asleep through lunch** — on wake, the first post-lunch tick runs the dedup-clear logic and auto-start fires.
6. **Auto-stop inside lunch window** — state is already idle (lunch forced `rest => idle` earlier). The auto-stop `shouldFire` check is true but `state != .idle` guard prevents `startStop()` being called. `lastAutoStopDate` is still recorded, preventing a re-fire. No crash, no double-action.

---

## 6. UI

### 6.1 Localization keys

Add to all three `.lproj` files (`en`, `ko`, `zh-Hans`):

| Key | en | ko | zh-Hans |
|---|---|---|---|
| `SettingsView.lunchPauseEnabled.label` | Pause for lunch | 점심 일시정지 | 午休暂停 |
| `SettingsView.lunchStartTime.label` | Lunch start | 점심 시작 | 午休开始 |
| `SettingsView.lunchDuration.label` | Lunch duration: | 점심 시간: | 午休时长: |

The existing `IntervalsView.min` format string (`"%d min"` / `"%d 분"` / `"%d 分"`) is reused for the Stepper duration label — no new format string is needed.

### 6.2 `SettingsView` layout

Add a new block below the auto-stop row:

- `Toggle` bound to `lunchPauseEnabled`
- When enabled (indented, matching existing style):
  - `DatePicker` for lunch start time, bound to `lunchStartTime`
  - `Stepper` for duration, range `15...180`, step `5`, bound to `lunchDurationMinutes`
- No day picker — weekdays are owned by the auto-start block and reused implicitly

---

## 7. Verification

### 7.1 Automated gates

Run after implementation before merging:

1. **Debug build** — `xcodebuild … build` → `** BUILD SUCCEEDED **`
2. **SwiftLint** — no new violations beyond the pre-existing `Log.swift:30` baseline warning
3. **Localization sync-check** — clean (no missing keys, no ghost references)

### 7.2 Manual smoke tests (fast-clock technique)

Use fast-clock offsets to move "now" relative to the lunch window for each scenario.

| # | Scenario | Expected |
|---|---|---|
| 1 | Default disabled — fresh install, toggle off | Sub-controls hidden |
| 2 | Toggle reveals sub-controls | Default 12:00 / 60 min shown |
| 3 | Stepper clamping | Stops at 15 and 180; increments by 5 |
| 4 | Happy-path pause | Auto-start, loop runs, lunch blocks `rest => work`, auto-resume at window end |
| 5 | No interruption of in-progress work | Manually started session runs to natural end before lunch takes effect |
| 6 | Manual loop without auto-start | Pauses at `rest => idle`; no auto-resume; user restarts manually |
| 7 | Auto-start dedup cleared at lunch end | Auto-start fires again within one 30-second tick after window closes |
| 8 | Wrong-day guard | If today not in `autoStartDays`, lunch window has no effect |
| 9 | Lunch + auto-stop interaction | Auto-stop inside window doesn't crash or double-fire |
| 10 | Backward compat | Existing auto-start configurations unchanged; new toggle defaults off |

---

## 8. Out of Scope

- Unit tests (no test target in the project)
- Cross-midnight lunch windows
- Multiple lunch windows per day
- Sound or notification at lunch start/end
- Status bar icon change during lunch (icon stays idle — correct, because the timer is idle)
