<p align="center">
<img src="TomatoBar/Assets.xcassets/AppIcon.appiconset/icon_128x128%402x.png" width="128" height="128"/>
<p>

<h1 align="center">Tiny Tomato Bar</h1>

<img
  src="screenshot.png"
  alt="Screenshot"
  width="50%"
  align="right"
/>

## Overview

A neat Pomodoro timer for the macOS menu bar. Configurable work and rest intervals, system sounds, discreet actionable notifications, and a global hotkey.

Available on the [Mac App Store](https://apps.apple.com/app/id6762198642).

Fully sandboxed with no entitlements.

## Features

- Configurable work, short rest, and long rest intervals
- Auto-start and auto-stop scheduling with per-day control
- System sound notifications (Purr for windup, Glass for completion)
- Global keyboard shortcut
- Localized in English, Korean, and Simplified Chinese
- Launch at login

## Integration

### Event log

Tiny Tomato Bar logs state transitions in JSON format to `~/Library/Containers/com.ploutonconsulting.veridian/Data/Library/Caches/TomatoBar.log`.

### URL scheme

Control the timer via `veridian://` URLs:
```
open veridian://startStop
```

## Attribution

Based on [TomatoBar](https://github.com/ivoronin/TomatoBar) by Ilya Voronin, licensed under the [MIT License](LICENSE).

## License

MIT License — see [LICENSE](LICENSE) for details.
