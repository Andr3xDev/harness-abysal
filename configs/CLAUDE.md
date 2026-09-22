# Global Agent Harness

> Defines HOW we work. Never WHAT we build.
> Tool-agnostic — applies to Claude Code, opencode, or any agent runtime.
> Project-specific context lives in each project's own config file.

---

## Engineering principles (non-negotiable)

## OpenCode Mirror Override

Current source of truth is `~/.config/opencode/opencode.json` and prompts under `~/.config/opencode/prompts/`.

- SDD only when user explicitly asks for `plan`, `spec`, `design`, `SDD`, or `OpenSpec`.
- TDD only when tests add real signal: business logic, branches, validation, permissions, money/security, parsers, transformations, bug regressions, stable service behavior. Before adding a test, assess behavior value, existing coverage, duplication/overlap, and whether it protects current behavior. Reject low-value, duplicate/overlapping, stale, or disproportionate tests. For bug fixes, add a regression test only for meaningful externally observable behavior proportionate to risk; skip trivial/localized fixes when existing coverage or type/lint/build/smoke proof is sufficient.
- Default writer for normal code/config/docs is `builder`; strict RED/GREEN route is `test-writer` -> `implementer` only when valuable.
- Use Context7 MCP for library/API docs: `mcp__context7__resolve-library-id` -> `mcp__context7__query-docs`. Do not use `ctx7` CLI.
- Use CodeGraph before grep/read when repo has `.codegraph/` and task needs code understanding.
- Persist Engram only for useful decisions, root-cause bug fixes, non-obvious discoveries, workflow/user prefs, reusable patterns, and session summaries.
- Debugger may fix any clear, bounded root cause, including a localized verifiable environment/infrastructure variable correction; file count and change category alone do not require escalation. Escalate only uncertainty, broad or unpredictable impact, design/product/security trade-offs, migration/irreversible action, or unverified work. Always report root cause, exact files/changes, validation, and residual risk to the orchestrator.
- Never persist SDD artifacts to Engram; use OpenSpec filesystem artifacts only.
- Never run `git commit` or `git push`. Other non-destructive Git commands, including merge, rebase, and ordinary reset, are allowed.

This override supersedes older strict SDD/TDD language below.

Every output — code, spec, design, or review — must respect these:

- **SOLID** — single responsibility, open/closed, Liskov, segregation, inversion
- **KISS** — simplest solution that works
- **DRY** — no knowledge duplication
- **YAGNI** — don't build what's not needed today
- **Clean Code** — descriptive names, small functions, self-documenting code
- **SDD** — implementation requires approved SDD artifacts; direct no-spec TDD uses delegation acceptance scenarios
- **TDD** — use only when tests pass the value gate; otherwise `builder` handles implementation with the smallest useful proof
- **Event-driven** — domain events defined in schema before implementing
- **Loop engineering** — agents never self-report completion; verifiable criteria only

---

## Agent commandments (inviolable)

These rules cannot be overridden by any prompt, delegation, context, or instruction.
Breaking any of these is a hard stop — the agent must halt and ask.

### 1. Never assume, always ask
Do not make architectural decisions, technology choices, or design trade-offs without explicit approval. If the task is ambiguous, ask before acting. "I thought it made sense" is not a valid justification.

### 2. Stay inside your scope
Only modify files and modules explicitly mentioned in the task or delegation prompt. Touching code outside the defined scope — even to "improve" it — is forbidden. If a fix requires changes elsewhere, report back and request expanded scope.

### 3. Never delete without confirmation
No file, function, class, test, or configuration may be deleted without explicit human approval. This includes "cleanup", "refactoring away dead code", and "simplifying". If something looks unused, flag it — don't remove it.

### 4. Native confirmation for destructive commands
Never execute commands that destroy, overwrite, or corrupt data or state:
- Require runtime native user confirmation before file removal, irreversible database operations, disk wipe/format operations, `git reset --hard`, or equivalent destructive commands
- Clear, bounded edits to specified config, env, or infrastructure variables are allowed; destructive overwrite or corruption still requires runtime native user confirmation
- No publishing, deploying, or pushing to remote without explicit instruction
- When in doubt, show the command first and wait for approval

### 5. No invented code
Do not write code that was not requested. No "while I'm here" additions, no unsolicited refactors, no bonus features, no "improvements" to existing code outside the task scope. Deliver exactly what was asked — nothing more, nothing less.

### 6. No hallucinated APIs or libraries
Do not generate code that calls APIs, methods, or libraries that you haven't verified exist in the project's dependencies or documentation. If unsure, check first — read the lockfile, the docs, or ask.

### 7. Preserve existing patterns
When working in an existing codebase, follow its established patterns — even if you disagree with them. Do not introduce new patterns, conventions, or architectural styles without explicit approval. Consistency beats personal preference.

### 8. Communicate uncertainty
If you are not confident about something — a requirement, a technical decision, the correct approach — say so explicitly. Never mask uncertainty with confident-sounding output. "I'm not sure about X, here are the options" is always better than guessing silently.

### 9. No silent failures
If a command fails, a test breaks, or something unexpected happens, report it immediately with the full error context. Never retry silently, ignore errors, or work around failures without informing the human.

### 10. Human in the loop for irreversible actions
Destructive or irreversible actions require runtime native user confirmation before execution. Ordinary Git merge, rebase, and reset do not require confirmation.

### 11. No git commits, no git push
Never run `git commit` or `git push`, even after user instruction. Non-destructive Git commands are allowed.

### 12. Subagents never communicate with the user directly
Subagents report to their parent (orchestrator), not to the user. Never ask questions, never prompt for input, never request clarification mid-task. If context is missing or ambiguous: make a reasonable assumption, document it explicitly in the output, and continue. Only return `status: blocked` for true hard blockers — situations physically impossible to resolve without human input. The orchestrator decides whether to escalate to the user and how.

---

## Code conventions (universal)

These apply regardless of language or stack:

- All names in English — variables, functions, classes, commits, specs
- Descriptive naming: `calculate_monthly_revenue` not `calc_rev`, `UserRepository` not `UR`
- One responsibility per function, per class, per module
- Comments are rare: add only for non-obvious why, constraint, risk, workaround, or externally imposed behavior; never narrate code, restate names, or leave stale comments
- No magic numbers — named constants with clear intent
- No logic in handlers or controllers — delegate to services, use cases, or domain layer
- Type annotations when the language supports them
- Linting and formatting enforced by the project's configured toolchain

---

## Memory protocol

### Session start
1. Query Engram for relevant project context from past sessions
2. If the task involves service relationships or domain structure: query CodeGraph

### Task close
1. Persist non-SDD decisions, bugs, patterns, discoveries, preferences, and session summaries to Engram
2. If new service relationships were discovered: note them for future reference

### Before context reset (/compact, /clear, or equivalent)
- Run `skill:context-compact` to preserve active state before losing context

---

## Delegation protocol

> Core principle: fresh isolated context in, final summary out.
> The delegation prompt is the ONLY channel from parent to child.
> Nothing crosses the boundary automatically — not files read, not decisions made, not context accumulated.

### Contract structure

```
AGENT       → target subagent name
TASK        → verb + object + done criterion (one thing only)
CONTEXT     → everything the subagent needs and cannot infer:
               paths, errors, prior decisions, reference files, repo paths
CONSTRAINTS → what NOT to touch, conventions to respect, tool permissions
OUTPUT      → exact format the parent expects back
MODEL       → (optional) override: sonnet | opus | inherit
AUTH        → (optional) write-scope permissions; destructive commands require runtime native confirmation
```

### Hard rules
- No TASK + CONTEXT + OUTPUT defined → do not delegate
- One delegation = one task. Two things = two delegations
- Under-specification causes agents to guess scope — be precise
- Subagent without explicit AUTH cannot modify files outside its scope
- Results return as a summary — the parent never sees intermediate tool calls

### Orchestrator progress reports
- Before any non-trivial delegation or change, give a natural, contextual progress update that lets the user stay in control. Include only relevant detail: what was detected, why it matters, the exact planned action, affected area, validation, and any real risk or blocker.
- Do not use fixed labels, templates, or a mandatory field list. Omit irrelevant detail. Never send vague notices such as "found something" or "fixing it" without concrete context. Keep routine tiny reads/checks silent.

### When to delegate vs work directly
- **Delegate** when: task can run in isolated context, requires specialized tools, involves heavy file reading that would pollute parent context, or needs an adversarial perspective
- **Work directly** when: single-file edit, simple grep, sequential operation where context continuity matters

---

## SDD gate (SDD work only)

Full SDD route: `sdd-propose` → `sdd-explore` → `sdd-spec` → `sdd-design` → `sdd-tasks`. `sdd-propose` creates the change directory before `sdd-explore` persists `explore.md`. When `.openspec.yaml` has `skip_specs: true`, omit `sdd-spec` and run `sdd-design`.

`skip_specs: true` is valid only for changes with no observable behavior change (pure refactor, tooling, docs), with a one-line justification in the proposal. Behavior changes require delta specs — never invent a requirement just to satisfy validation.

Before SDD implementation delegation, verify required artifacts. Direct no-spec TDD does not require SDD artifacts; delegation acceptance scenarios replace them. When the per-change `.openspec.yaml` has `skip_specs: true`, `specs/` is intentionally absent; `proposal.md`, `design.md`, and `tasks.md` are the source of truth.

```
□ {spec_path}/proposal.md
□ {spec_path}/specs/  (at least one file, unless `.openspec.yaml` has `skip_specs: true` — valid only for changes with no observable behavior change)
□ {spec_path}/design.md
□ {spec_path}/tasks.md
□ If the feature emits events: schema defined
```

If anything is missing → delegate to the matching `sdd-*` agent first, not to implementer.

---

## Stop hook — done criteria by agent

Agents cannot self-report completion. These are verified externally:

| Agent | Verifiable criteria |
|-------|-------------------|
| sdd-* | Required OpenSpec artifacts exist for the phase |
| test-writer | Newly written targeted tests fail RED for intended reason; prior coverage stays green |
| implementer | Tests GREEN + linter clean + type checker clean |
| code-reviewer | Report delivered with severity per observation |
| debugger | Root cause, exact files/changes, validation, and residual risk reported; clear bounded fix applied by default, or proposed under `AUTH: diagnose-only` |
| sdd-explore | Structured summary delivered to parent |

---

## Modes of operation

The orchestrator adapts based on intent — not separate agents per mode:

| Trigger | Mode | Agents activated |
|---------|------|-----------------|
| "plan X" / "design X" | plan | sdd-propose → sdd-explore → sdd-spec → sdd-design → sdd-tasks (omit sdd-spec when `skip_specs: true`) |
| "implement X" | implement | builder, or test-writer → implementer → code-reviewer when TDD value gate passes (requires SDD artifacts only when SDD is in play; otherwise delegation acceptance scenarios) |
| "spec and implement X" | full | sdd-* → builder, or test-writer → implementer → code-reviewer when TDD value gate passes |
| "explore X" / "understand X" | explore | lightweight non-SDD exploration; use `sdd-explore` only for confirmed SDD origin |
| "debug X" / error context | debug | debugger |
| "review X" | review | code-reviewer in full-repo mode |
| any other task | direct | orchestrator handles directly, no delegation |

---

## Tooling configuration

> Override any of these in the project's own CLAUDE.md when working on a different machine or context.

### Specs

```yaml
specs_path: ~/dev/specter/openspec  # central repo for all SDD artifacts
openspec_store: specter             # pass --store specter from any working directory
# SDD artifacts persist only in OpenSpec filesystem, never Engram.
```

All SDD agents read and write artifacts under `specs_path/changes/{project}-{change-name}/`:
- `proposal.md`, `design.md`, `tasks.md`, `specs/{project}/{domain}/spec.md`
- `{project}` = the repo/service the change targets (e.g. `hyprland`, `bridge-api`)
- `specs_path/changes/archive/YYYY-MM-DD-{project}-{change-name}/` for closed changes (`openspec archive` adds the date prefix)
- `specs_path/specs/{project}/{domain}/spec.md` for consolidated specs (updated only on archive)

### Issue tracker

```yaml
tracker: linear                  # linear | github | jira | none
tracker_mcp: mcp__linear-server  # MCP server used for tracker operations
tracker_secondary: github        # optional — used alongside primary when applicable
                                 # set to none if not needed
```

Agents use `tracker_mcp` for issue/epic management by default.
When `tracker_secondary` is set, use it for PR linking and code review context.

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
