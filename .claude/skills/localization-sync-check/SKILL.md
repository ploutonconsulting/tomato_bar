---
name: localization-sync-check
description: Verify that every localization key in TomatoBar/en.lproj/Localizable.strings also exists in ko.lproj and zh-Hans.lproj, and that every NSLocalizedString key referenced in Swift source is present in en.lproj. Use after adding, removing, or editing any NSLocalizedString call, or after touching any Localizable.strings file.
---

# localization-sync-check

Repo-scoped advisor for Tomato Bar. TomatoBar is localized into **en**, **ko**, and **zh-Hans**; keys drift silently when developers add a new `NSLocalizedString(...)` call and forget to update all three `Localizable.strings` files. This skill catches that drift.

## When to use

- Immediately after editing any `TomatoBar/*.lproj/Localizable.strings` file.
- Immediately after adding, removing, or renaming an `NSLocalizedString(...)` call in any `TomatoBar/*.swift` file.
- When the user says "check translations", "localization check", "lproj check", "sync localizations", or similar.
- Before `git commit` on a branch that touches Swift or .strings files.

## Output only — this skill is an advisor

Never auto-edit any `.strings` file. Translations need human judgement. Report drift; leave the fix to the user (or a follow-up task they explicitly ask for).

## Workflow

### Step 1 — Extract keys from each locale

`Localizable.strings` lines look like:

```
"SettingsView.autoStartEnabled.label" = "Auto-start timer";
```

Use a simple grep/awk to pull keys (the text between the first pair of quotes on each line):

```bash
cd "$CLAUDE_PROJECT_DIR"

extract_keys() {
  # $1 = path to Localizable.strings
  # Emits unique key names, one per line, sorted.
  grep -Eo '^[[:space:]]*"[^"]+"' "$1" \
    | sed -E 's/^[[:space:]]*"([^"]+)".*/\1/' \
    | sort -u
}

en_keys=$(extract_keys TomatoBar/en.lproj/Localizable.strings)
ko_keys=$(extract_keys TomatoBar/ko.lproj/Localizable.strings)
zh_keys=$(extract_keys TomatoBar/zh-Hans.lproj/Localizable.strings)
```

### Step 2 — Extract NSLocalizedString keys from Swift source

```bash
swift_keys=$(grep -rhEo 'NSLocalizedString\("[^"]+"' TomatoBar --include='*.swift' \
  | sed -E 's/NSLocalizedString\("([^"]+)"/\1/' \
  | sort -u)
```

### Step 3 — Compute drift

Use `comm` or `grep -vxF` to produce three sets:

1. **Missing in ko** — keys in `en_keys` but not in `ko_keys`.
2. **Missing in zh-Hans** — keys in `en_keys` but not in `zh_keys`.
3. **Ghost references** — keys in `swift_keys` but not in `en_keys`. These are high severity — they'll display the raw key at runtime instead of a localized string.

Optionally (low severity): keys in `en_keys` that no `NSLocalizedString` call references — candidates for cleanup.

### Step 4 — Report

Print a markdown summary. Example layout (skip any section that's empty):

```markdown
## Localization Sync Check

**Summary:** 2 keys missing in ko, 2 keys missing in zh-Hans, 0 ghost references.

### Missing in ko.lproj
- `SettingsView.autoStopEnabled.label`
- `SettingsView.autoStopTime.label`

### Missing in zh-Hans.lproj
- `SettingsView.autoStopEnabled.label`
- `SettingsView.autoStopTime.label`

### Ghost references (Swift calls NSLocalizedString with key not in en.lproj)
_(none — clean)_

### Suggested next step
Two new keys need translation. I can generate placeholder entries in ko.lproj and zh-Hans.lproj copying the English value — want me to do that, or will you supply translations?
```

If everything is clean, the entire report should be a single line: `Localization: clean ✓ (en ↔ ko ↔ zh-Hans all in sync, no ghost references)`.

## Safety

- **Read-only.** This skill never edits `.strings` or Swift files.
- **Exit 0 always.** Drift is not an error — it's a report for the user to act on.
- **Scope matters.** Only scan files under `TomatoBar/`. Ignore `Build/`, `.github/`, `.claude/`, and any other directory.
