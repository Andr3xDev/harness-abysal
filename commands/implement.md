---
description: Implement a planned change — use TDD only when its value gate passes
---

Activate IMPLEMENT MODE for: $ARGUMENTS

Follow the orchestrator's implement mode workflow:
1. Detect working directory and project context
2. Only for confirmed explicit SDD origin, read change `.openspec.yaml`. If `skip_specs: true`, `specs/` is intentionally absent; `proposal.md`, `design.md`, and `tasks.md` are source of truth, and do not delegate `sdd-spec`. Otherwise require `specs/`. Validate with `openspec validate "<change-id>" --store specter --json`.
3. Assess test behavior value, existing coverage, duplication/overlap, current-behavior protection, and proportional risk. If it passes, delegate: test-writer (red) → implementer (green) → code-reviewer. If it fails, delegate: builder → code-reviewer. Failed test gate routes to builder, not TDD.
4. For SDD origin, after all tasks complete: delegate to sdd-verify and present its report. For direct lanes, close after normal proof and clean review.

If "$ARGUMENTS" references a specific task or subset, implement only those.
