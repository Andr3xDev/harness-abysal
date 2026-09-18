# SDD Phase — Common Protocol

Boilerplate shared across all SDD phase agents.
Sub-agents MUST follow this alongside their phase-specific instructions.

---

## A. Executor boundary

Every SDD phase agent is an EXECUTOR, not an orchestrator.
Do the phase work yourself. Do NOT launch sub-agents, do NOT call the Task tool,
and do NOT bounce work back unless the phase explicitly says to stop and report a blocker.

---

## B. Skill loading

1. Check if the orchestrator injected a `## Skills to load before work` block in your
   delegation prompt. If yes, read those exact SKILL.md files before starting.
2. If no skills block was provided, proceed with your phase instructions only.
3. The orchestrator resolves skills — sub-agents do not self-discover.

---

## C. Artifact retrieval (OpenSpec filesystem)

Full SDD runs only for confirmed explicit SDD origin. Its artifacts live only in the configured OpenSpec change directory:
`{specs_path}/changes/{project}-{change-name}/`.

Full route: `sdd-propose` → `sdd-explore` → `sdd-spec` → `sdd-design` → `sdd-tasks`.
`sdd-propose` creates the change directory before `sdd-explore` persists `explore.md`.
When `skip_specs: true`, omit `sdd-spec` and run `sdd-design`.

Read every complete artifact file needed for the phase. When `.openspec.yaml` has
`skip_specs: true`, `specs/` is intentionally absent; use `proposal.md`, `design.md`,
and `tasks.md` as source of truth. Do not use Engram to retrieve SDD artifacts.

---

## D. Artifact persistence (OpenSpec filesystem)

Every phase that produces an artifact MUST persist it.
Skipping this BREAKS the pipeline — downstream phases will not find your output.

Write the complete artifact to its OpenSpec file under
`{specs_path}/changes/{project}-{change-name}/`. Do not save SDD artifacts to Engram.

### Artifact types

| Artifact | OpenSpec path | Produced by |
|----------|---------------|-------------|
| proposal | `proposal.md` | sdd-propose |
| explore | `explore.md` | sdd-explore |
| spec | `specs/{capability}/spec.md` | sdd-spec |
| design | `design.md` | sdd-design |
| tasks | `tasks.md` | sdd-tasks |
| apply-progress | `apply-progress.md` | implementer |
| verify-report | `verify-report.md` | sdd-verify |
| archive-report | `archive-report.md` | sdd-archive |
| state | `state.yaml` | orchestrator |

---

## E. Return envelope

> **CRITICAL — Response ordering**: write OpenSpec artifacts BEFORE your
> final text response. Your last output MUST be text, NOT a tool call.
> If you end with a tool call, the orchestrator receives only the tool result —
> your analysis is lost.

Every phase MUST return this structured envelope:

```
status: done | blocked | partial
executive_summary: 1-3 sentence summary of what was done
artifacts: list of artifact keys or paths written
next_recommended: next SDD phase to run, or "none"
risks: risks discovered, or "none"
```

Do not save SDD artifacts to Engram. The orchestrator handles non-SDD session summaries
under the global memory protocol.

---

## F. PR review workload guard

SDD must protect reviewer cognitive load:

- Default PR review budget: **400 changed lines** (additions + deletions)
- `sdd-tasks` MUST forecast whether the planned work exceeds that budget
- If forecast is High: recommend splitting into chained work units
- Include in tasks.md: `PR size risk: Low | Medium | High`
- Each work unit must have: clear start, clear finish, autonomous scope, verification

---

## G. Persistence

SDD always reads and writes OpenSpec filesystem artifacts under
`{specs_path}/changes/{project}-{change-name}/`. Git history provides the audit trail.
Engram is not an SDD artifact store and has no SDD persistence mode or fallback.
