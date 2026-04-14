---
title: TomatoBar — Project
version: 1.0
created: 2026-04-14
updated: 2026-04-14
tags:
  - tomatobar
  - project-management
---

# TomatoBar — Project

## Mission

TomatoBar is the world's neatest Pomodoro timer for the macOS menu bar — configurable work and rest intervals, optional sounds, discreet notifications, and a global hotkey, all in a fully sandboxed app.

## Milestones

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| Auto-start/auto-stop scheduling | 2026-04-09 | Complete |
| Lunch pause feature (removed) | 2026-04-09 | Removed |
| Localization (en, ko, zh-Hans) | — | Complete |

## Risks

| ID | Risk | Impact | Likelihood | Mitigation |
|----|------|--------|------------|------------|
| R1 | No test target — regressions caught late | Medium | Medium | SwiftLint + xcodebuild skill as safety net |
| R2 | Localization key drift across 3 locales | Low | Medium | Localization sync check skill + PostToolUse hook |

## Issues

| ID | Description | Priority | Owner | Status |
|----|-------------|----------|-------|--------|
|    |             |          |       |        |

## Tasks

| ID | Task | Owner | Due | Status |
|----|------|-------|-----|--------|
|    |      |       |     |        |

## Stakeholders

| Name | Role | Contact |
|------|------|---------|
| Pierre Oosthuizen | Maintainer / Developer | — |
| Ilya Voronin | Original author | GitHub: ivoronin |

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-09 | Add auto-start and auto-stop scheduling | Users want hands-free timer management during work hours |
| 2026-04-09 | Add lunch pause feature | Pause timer during lunch window |
| 2026-04-14 | Remove lunch pause feature | Feature was not satisfactory; clean removal preferred |
| 2026-04-14 | Add SwiftLint hook and xcode-build-check skill | No test target — automated lint and build checks are the primary safety net |

---

## Related Documents

- [[ARCHITECTURE]] — System design, components, data models
- [[DECISIONS]] — Architecture Decision Records
- [[DOMAIN]] — Business domain and glossary
- [[UI-DESIGN]] — Design system, screens, UX flows, brand
- [[LOGGING]] — Logging strategy and rules
- [[TOOLS]] — Tools and automation
- [[LEGAL]] — Copyright, licences
