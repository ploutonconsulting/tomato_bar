---
title: TomatoBar — Domain
version: 1.0
created: 2026-04-14
updated: 2026-04-14
tags:
  - tomatobar
  - domain
---

# TomatoBar — Domain

## Business Context

TomatoBar helps knowledge workers maintain focus and manage energy by implementing the Pomodoro Technique as a macOS menu-bar app. It provides configurable work/rest cycles with minimal friction — always visible, one click to start.

## User Personas

### Focused Worker
A developer, writer, or student who uses Pomodoro to maintain concentration during deep work. Values simplicity, minimal distraction, and reliable timing.

### Scheduled Worker
A professional who wants the timer to auto-start at the beginning of their workday and auto-stop at the end. Values hands-free operation with day-of-week control.

## Domain Model

### Pomodoro Cycle
A repeating pattern of work intervals followed by rest intervals. After a configurable number of work intervals (default 4), a long rest replaces the short rest.

### Timer States
- **Idle** — no active timer
- **Work** — timed focus interval
- **Rest** — timed break (short or long)

### Schedule Rules
Time-of-day triggers (minutes since midnight) combined with weekday bitmasks that control automatic start/stop of the Pomodoro cycle.

## Glossary

| Term | Definition |
|------|-----------|
| Pomodoro | A time management technique using timed work intervals separated by breaks |
| Work interval | A focused work period (default 25 minutes) |
| Short rest | A brief break between work intervals (default 5 minutes) |
| Long rest | An extended break after completing a set of work intervals (default 15 minutes) |
| Work set | A group of consecutive work intervals (default 4) before a long rest |
| Overrun | Negative time displayed after a timer expires, showing how long the user delayed |
| Menu bar | The macOS system-wide bar at the top of the screen where TomatoBar's icon lives |

---

## Related Documents

- [[ARCHITECTURE]] — System design
- [[PROJECT]] — Project context
- [[UI-DESIGN]] — UX and user flows
