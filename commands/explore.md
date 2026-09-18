---
description: Explore and understand a codebase, repo, service, or feature area
---

Activate EXPLORE MODE for: $ARGUMENTS

Follow the orchestrator's explore mode workflow:
1. Detect working directory and project context
2. Use lightweight non-SDD exploration for the target: "$ARGUMENTS". Delegate to sdd-explore only for confirmed SDD origin.
3. If "$ARGUMENTS" references multiple repos: include all paths in the delegation
4. Present structured summary
5. Persist only non-SDD findings that meet the Engram value gate

This is read-only exploration — no files modified, no specs created.
