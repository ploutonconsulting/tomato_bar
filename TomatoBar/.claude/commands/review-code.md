---
description: Review highlighted code, specified method(s)/class(es), or the current file
allowed-tools: Read, Write, Edit
---

Determine the review scope:
- If `$ARGUMENTS` is provided: review only the highlighted code or the specified method(s) and class(es).
- If nothing is highlighted or specified (`$ARGUMENTS` is empty): read and review the current file in full.

For the identified scope, improve its documentation:

1. Add a clear docstring/JavaDoc explaining:
   - What the method/class does (one sentence)
   - Parameters and their purpose
   - Return value
   - Any exceptions thrown

2. Add inline comments only where:
   - Logic is non-obvious
   - Complex algorithms need clarification
   - Edge cases are handled

3. Follow these principles:
   - Be concise - no redundant comments
   - Explain "why", not "what" (code shows what)
   - Use proper documentation format for the language
   - Keep comments under 80 characters per line

4. SOLID principles check:
   After documenting, run /apply-SOLID-principles on the same file.
   If violations are found, report them alongside the documentation summary
   but do not apply fixes — present them as a separate follow-up action for
   Pierre to confirm.

After making changes, show a brief summary covering:
- What was reviewed (scope: highlighted code / named method or class / full file)
- What was documented
- Any SOLID violations found (or confirm all principles are satisfied)
