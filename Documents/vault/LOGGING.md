---
title: TomatoBar — Logging
version: 1.0
created: 2026-04-14
updated: 2026-04-14
tags:
  - tomatobar
  - logging
---

# TomatoBar — Logging Strategy

## Overview

TomatoBar uses a custom structured logging system defined in `Log.swift`. Events are logged as typed objects (e.g. `TBLogEventAppStart`) rather than free-form strings.

## Log Levels

| Level | When to use |
|-------|------------|
| ERROR | Unrecoverable failures requiring immediate attention |
| WARN  | Recoverable issues, unexpected but handled states |
| INFO  | Normal operational events (startup, shutdown, key user actions) |
| DEBUG | Detailed diagnostic information (dev only) |

## Log Categories

| Category | Description |
|----------|------------|
| App lifecycle | App start, termination |
| Timer events | State transitions (idle → work → rest), interval completion |
| Schedule events | Auto-start/auto-stop trigger decisions |

## What NOT to Log

- No sensitive user data (this app has none, but maintain the principle)
- Avoid high-frequency timer tick logs in production builds

---

## Related Documents

- [[TOOLS]] — Logging frameworks and tools
- [[LEGAL]] — Data retention and compliance requirements
