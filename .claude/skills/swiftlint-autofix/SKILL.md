---
name: swiftlint-autofix
description: Run SwiftLint --fix on Swift files in TomatoBar, then report any violations the autocorrector couldn't fix. Use after editing any .swift file in this repo, or invoke manually (e.g. /swiftlint-autofix) to clean up the working tree before committing.
---

# swiftlint-autofix

Repo-scoped skill for Tomato Bar. This project has no test target, so SwiftLint is the primary automated safety net for code style. Always invoke this skill after writing or editing Swift files so that style drift is corrected while the change is still fresh.

## When to use

- After Claude (or the user) edits any file under `TomatoBar/` matching `*.swift`.
- When the user says "lint", "check lint", "run swiftlint", "clean up style", "fix formatting", or any equivalent phrasing.
- Before running `git commit` or `gh pr create` on a branch that contains Swift edits.

Don't run this skill on non-Swift files — it's a no-op outside `*.swift`.

## Prerequisites

`swiftlint` must be on `PATH`. If it's missing, follow the graceful-failure flow below — do **not** error out the session.

## Workflow

### Step 1 — Check that swiftlint is available

```bash
command -v swiftlint >/dev/null 2>&1 || {
  echo "swiftlint is not installed."
  echo "Install it with: brew install swiftlint"
  echo "(Skipping autofix — this is not a failure.)"
  exit 0
}
```

Exit cleanly (status 0) if swiftlint is missing. Surface the install hint to the user but do not raise an error.

### Step 2 — Determine which files to lint

- **Automatic trigger (after an edit):** lint only the file that was just modified (use the path the tool received).
- **Manual trigger (no specific file):** lint the entire `TomatoBar/` directory.

Never lint outside `TomatoBar/` — don't touch `Build/`, `.github/`, `Icons/`, or any generated folder.

### Step 3 — Run the autocorrector, then report residuals

```bash
cd "$CLAUDE_PROJECT_DIR"

# Autofix pass — writes changes in place.
swiftlint --fix --quiet <target>

# Report pass — surfaces anything the autofixer couldn't fix.
swiftlint lint --quiet <target>
```

Where `<target>` is either the single edited file or `TomatoBar/`.

### Step 4 — Summarise to the user

Produce a short markdown summary with three possible sections (skip any that are empty):

- **Auto-fixed**: files modified by `--fix` (from the first command's stdout).
- **Remaining violations**: items from the second `swiftlint lint` command, grouped by file, with `file:line — rule — message`.
- **Action needed**: only if there are remaining violations, one-sentence nudge to the user with a suggested next step (usually "I can fix these — want me to?").

If both commands produce no output, say `SwiftLint: clean ✓` and stop.

## Respect the project's lint config

This repo has a `.swiftlint.yml` at the root with two disabled rules (`trailing_comma`, `opening_brace`). `swiftlint` picks it up automatically — do **not** pass `--config`. Do **not** edit `.swiftlint.yml` to make violations go away; instead fix the code, or ask the user whether to disable the rule if it's genuinely inappropriate.

## Safety

- **Never commit.** Leave the working tree dirty so the user can review the autocorrected diff.
- **Never reformat generated files.** Only touch files under `TomatoBar/` that are tracked Swift source.
- **Never edit `TomatoBar.xcodeproj/project.pbxproj`, `TomatoBar.entitlements`, or `export_options.plist`** even if swiftlint flags something in them — those files are signing-critical.
