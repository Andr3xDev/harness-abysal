---
description: Debug an error, failing test, or production issue
---

Activate DEBUG MODE for: $ARGUMENTS

Follow the orchestrator's debug mode workflow:
1. Detect working directory and project context
2. Search Engram for prior occurrences of this error
3. Delegate to debugger with:
   - Error context from "$ARGUMENTS" (stack trace, error message, reproduction steps)
   - AUTH: autonomous-small-fix (default). Use AUTH: diagnose-only only for an explicit investigation-only request
4. Present debugger report: root cause, exact files/changes, validation, and residual risk
5. If debugger applied a fix from confirmed SDD origin: run sdd-verify. Otherwise close after debugger proof.

If "$ARGUMENTS" is a stack trace, pass it verbatim to the debugger.
