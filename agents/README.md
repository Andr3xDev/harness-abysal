<h1 align="center">Claude Code Sub-Agents</h1>

<p align="center">Multi-agent engineering harness — agent roster, delegation rules, and enforcement</p>

<br>

## What is this directory

This directory holds the sub-agent definitions used by Claude Code for the multi-agent engineering harness: `strategist.md`, `tech-orchestrator.md`, and the phase agents under `sub-agents/sdd/` (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-verify`, `sdd-archive`), plus `builder`, `implementer`, `test-writer`, `code-reviewer`, `judge-a`/`judge-b`, and the read-only infrastructure agents (`aws`, `log-reader`, `codegraph-maintainer`).

It is a mirror of `/home/andrex/.config/opencode/prompts/` (OpenCode). Both mirrors must stay behaviorally equivalent — any change made to an agent in one mirror must be replicated in the other.

<br>

## How SDD changes get archived

`sdd-archive` (`/home/andrex/.claude/agents/sub-agents/sdd/sdd-archive.md`) closes a change using the real `openspec` CLI instead of moving folders by hand:

```bash
openspec archive "<project>-<change-name>" -y
```

Before archiving, the agent requires a passing verification report from Engram and refuses to proceed if it's missing or has CRITICAL findings.

If the CLI archive command is unavailable or fails, the agent falls back to the manual pattern from the reference `openspec-archive-change` skill, documented directly in the file:

- `openspec status --change "<name>" --json` to read `changeRoot` / `planningHome.changesDir` and check artifact completion
- Read `tasks.md` and flag (not block) incomplete tasks
- `mkdir -p "<changesDir>/archive"` then `mv "<changeRoot>" "<changesDir>/archive/YYYY-MM-DD-<name>"`

Change-name convention (`{project}-{change-name}`, kebab-case, hyphens only) is defined once at `/home/andrex/dev/specter/openspec/AGENTS.md` and validated by `sdd-propose` before a change is created — this README does not duplicate that rule.

<br>

## How the strategist delegates

`strategist.md` has a "Delegation scope (inviolable)" section (around lines 98-110) restricting it to four SDD validation agents:

- `sdd-explore`
- `sdd-propose`
- `sdd-spec`
- `sdd-design`

The strategist may never invoke `Task` toward `implementer`, `test-writer`, `builder`, `sdd-tasks`, `sdd-verify`, or `sdd-archive` — those are execution-phase agents owned by the orchestrator. If a discussion reaches that phase, the strategist hands off to the orchestrator instead of delegating itself.

This boundary is a prompt-level lock, not a technical one — Claude Code's `Task` tool has no built-in mechanism to restrict which target agent a given caller can invoke. Enforcement depends entirely on the agent's own instructions being followed.

<br>

## How skills get injected

The authoritative table lives in `/home/andrex/.claude/skills/skill-registry/SKILL.md` under "Mandatory Skill Assignments" and "Conditional Skill Triggers." Summary of the mandatory assignments:

| Agent | Mandatory skill |
|---|---|
| builder | ponytail |
| implementer | ponytail |
| test-writer | ponytail |
| sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-verify, sdd-archive | karpathy-guidelines |
| code-reviewer, judge-a, judge-b, strategist | karpathy-guidelines |
| aws, log-reader, codegraph-maintainer | none — read-only infrastructure |

`ponytail` and `karpathy-guidelines` are mutually exclusive on a given agent: `ponytail` only goes to agents that write code (`builder`, `implementer`, `test-writer`), `karpathy-guidelines` only to planning/review agents. The registry explicitly says do not load both on the same agent, and do not load either on agents not listed.

Conditional skills (`find-docs`, `md-style-guide`, `refactoring-techniques`, `senior-architect`, `software-design-patterns`, `event-schema`, `judgment-day`) are injected only when the task text matches the listed trigger keywords for that agent — see the Conditional Skill Triggers table in the registry for the exact keyword lists per agent.

<br>

## Enforcement of permissions (AUTH gates)

In OpenCode, permissions are granular per command via `opencode.json` (`allow`/`ask`/`deny` per agent). Claude Code has no equivalent native mechanism — there is no per-agent command allow-list built into the agent frontmatter beyond `tools`/`disallowedTools`. The gap is closed with `PreToolUse` hooks registered in `settings.json`.

`/home/andrex/.claude/hooks/infra-agent-bash-guard.py` is the reference implementation of this pattern. It intercepts `Bash` calls, keyed on `agent_type`, mirroring the allow-lists already defined in `opencode.json` for the same agents. `code-reviewer` joined this enforcement pattern so it can run tests/linters to verify coverage/quality claims without gaining open shell access.

| Agent | Allow | Ask | Deny |
|---|---|---|---|
| aws | `aws logs describe-*`, `aws dynamodb *`, `aws lambda get-*`/`list-*`, `aws ecs describe-*`/`list-*`, `aws ec2 describe-*`, `git *` | `git reset --hard*` | `git commit*`, `git push*` |
| log-reader | `rg *`, `wc *`, `du *`, `ls *`, `zcat *`, `gzip -cd *`, `journalctl *`, `docker logs *`, `kubectl logs *`, `git *` | `git reset --hard*` | `git commit*`, `git push*` |
| codegraph-maintainer | `codegraph status/query/explore/files/node/callers/callees/impact/affected`, `git *` | `git reset --hard*`, `codegraph unlock/init/sync/index*`, `codegraph-health*` | `git commit*`, `git push*` |
| code-reviewer | `npm test*`/`npm run test*`/`npm run lint*`, `yarn test*`/`lint*`, `pnpm test*`/`lint*`, `pytest*`, `python -m pytest*`, `go test*`/`vet*`, `cargo test*`/`clippy*`, `ruff*`, `eslint*`, `flake8*`, `mypy*`, `rubocop*`, `bundle exec rspec*`, `mvn test*`, `gradle test*`, `make test*`, `tox*`, `git *` | `git reset --hard*` | `git commit*`, `git push*` |

Any command not matched by `allow` or `ask` falls through to `deny`. Any `agent_type` not in the `RULES` dict passes through untouched — the hook never affects the main thread or agents outside this list.

This is the pattern to reuse if another agent needs a Bash restriction in the future — for example, `test-writer` arguably should not touch production code paths. Today that boundary is prompt discipline only (documented in `test-writer`'s own instructions); no hook enforces it. This is a known gap, not yet addressed.

### Extension: `debugger` Edit gate

`debugger` is different from the three agents above: its AUTH gate (`diagnose-only` vs `apply-fix`) is not a fixed per-agent allow-list, it varies *per delegation* — the orchestrator states it in the text of each delegation prompt. A `PreToolUse` hook only receives `tool_name` and `agent_type` on stdin; it never sees the delegation prompt itself, so it has no way to tell whether a given `Edit` call happened under `diagnose-only` or `apply-fix`. Conditionally blocking only the `diagnose-only` case is therefore not possible at the hook layer — that distinction exists only in text invisible to the hook.

Given that limitation, the technical enforcement added is unconditional: `infra-agent-bash-guard.py` now also intercepts `Edit` (via a second `PreToolUse` matcher in `settings.json`), and returns `"ask"` for every `Edit` call made by `agent_type == "debugger"`, regardless of AUTH. This does not break `apply-fix` mode — the user just confirms, as expected — but it closes the gap where a `diagnose-only` delegation could otherwise edit production code with nothing but a prompt-level promise standing in the way. It is a floor (always confirm), not a precise gate (confirm only when unauthorized); the AUTH text in the delegation prompt is still what tells the human confirming whether the edit was actually authorized.

Coverage after this change: `aws` / `log-reader` / `codegraph-maintainer` are Bash-gated as above; `debugger` is Edit-gated as described here. Bash behavior for `debugger` is unchanged (still full framework/native permissions, no hook rule).

In OpenCode, the mirrored change is `permission.edit` for the `debugger` agent in `opencode.json`, flipped from `"allow"` to `"ask"` — same reasoning, same limitation (OpenCode's permission engine also can't see per-delegation AUTH text, only the static per-agent config).

<br>

## Circuit breaker

`tech-orchestrator.md`, "Validation and close" section: if `code-reviewer` reports the same BLOCKER on the same finding/file 3 times in a row, the orchestrator stops the reviewer-implementer cycle and escalates to the human instead of iterating further.

<br>

## Parity between Claude Code and OpenCode

Both mirrors (`/home/andrex/.claude/agents/` and `/home/andrex/.config/opencode/prompts/`) must stay behaviorally equivalent. Any change to an agent in one mirror must be replicated in the other.

This parity requirement is the origin of the recent cleanup pass reflected in this README: real contradictions had been found between the two mirrors (for example, diverging `sdd-spec` paths), since corrected by migrating both mirrors to the real `openspec` CLI archive flow described above.
