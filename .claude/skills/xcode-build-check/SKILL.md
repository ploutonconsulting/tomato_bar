---
name: xcode-build-check
description: Build TomatoBar with xcodebuild and report success or parsed errors. Use after modifying Swift files to verify the project compiles, or invoke manually with /xcode-build-check.
---

# xcode-build-check

Repo-scoped skill for Tomato Bar. Builds the project and surfaces compile errors in a concise format so Claude or the user can act on them quickly.

## When to use

- After editing Swift files to verify the project still compiles.
- When the user says "build", "check build", "does it compile", "xcodebuild", or similar.
- Before `git commit` or `gh pr create` on a branch with Swift changes.

## Workflow

### Step 1 -- Build

```bash
cd "$CLAUDE_PROJECT_DIR"
xcodebuild build \
  -scheme TomatoBar \
  -configuration Debug \
  -destination 'platform=macOS' \
  2>&1 | tee /tmp/tomatobar-build.log | tail -5
```

### Step 2 -- Check result

```bash
if grep -q "BUILD SUCCEEDED" /tmp/tomatobar-build.log; then
  echo "Build: clean"
else
  echo "Build FAILED. Errors:"
  grep -E "error:" /tmp/tomatobar-build.log | head -20
fi
```

### Step 3 -- Report

- **Success**: `Build: clean` -- stop here.
- **Failure**: List each error as `file:line -- message`. If there are warnings, list them separately. Suggest fixes if the errors are straightforward.

## Safety

- **Read-only build.** This skill only compiles; it never modifies source files.
- **Debug configuration only.** Never build Release (avoids code-signing issues in dev).
- **Clean build output.** The temp log at `/tmp/tomatobar-build.log` is overwritten each run.
