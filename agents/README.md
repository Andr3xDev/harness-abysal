<h1 align="center">Claude Code Sub-Agents</h1>

<p align="center">Multi-agent engineering harness — agent roster, delegation rules, and enforcement</p>

<br>

## What is this directory

This directory holds the sub-agent definitions used by Claude Code for the multi-agent engineering harness: `strategist.md`, `tech-orchestrator.md`, and the phase agents under `sub-agents/sdd/` (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-verify`, `sdd-archive`), plus `builder`, `implementer`, `test-writer`, `code-reviewer`, `judge-a`/`judge-b`, infrastructure agents (`aws`, `log-reader`, `codegraph-maintainer`, `engram-maintainer`), and the vault agents under `sub-agents/echor/` (`echor-onboarder`, `echor-updater`, `echor-consultador`, `echor-validator`).

It is a mirror of `/home/andrex/.config/opencode/prompts/` (OpenCode). Both mirrors must stay behaviorally equivalent — any change made to an agent in one mirror must be replicated in the other.

TDD runs only when behavior value, existing coverage, duplication/overlap, and protection of current behavior justify it. Low-value, duplicate/overlapping, stale, or disproportionate tests are rejected. Otherwise `builder` handles work with the smallest useful proof. Bug regressions require meaningful externally observable behavior proportionate to risk.

<br>

## How SDD changes get archived

`sdd-archive` (`/home/andrex/.claude/agents/sub-agents/sdd/sdd-archive.md`) closes a change using the real `openspec` CLI instead of moving folders by hand:

```bash
openspec archive "<project>-<change-name>" -y --store specter
```

Before archiving, the agent requires `{change-folder}/verify-report.md` and refuses to proceed if it is missing or has CRITICAL findings.

If the CLI archive command is unavailable or fails, archive blocks. `sdd-archive` reports the command and failure to the orchestrator; it never creates directories or moves change folders manually.

Change-name convention (`{project}-{change-name}`, kebab-case, hyphens only) is defined once at `/home/andrex/dev/specter/openspec/AGENTS.md` and validated by `sdd-propose` before a change is created — this README does not duplicate that rule.

SDD commands use registered store `specter` from any working directory: `openspec <subcommand> ... --store specter`. Check registration with `openspec store list`; global structural validation is `openspec validate --all --strict --store specter`.

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

The authoritative role policy lives in `opencode/skills/skill-registry/SKILL.md` and is shared by both runtimes. Its mandatory assignments are:

| Agent | Mandatory skill |
|---|---|
| builder | ponytail |
| implementer | ponytail |
| test-writer | ponytail |
| orchestrator, strategist | caveman, karpathy-guidelines |
| sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-verify, sdd-archive | karpathy-guidelines, SDD protocol, md-style-guide |
| debugger, code-reviewer, judge-a, judge-b | karpathy-guidelines |
| aws, log-reader, codegraph-maintainer, engram-maintainer | none — infrastructure |
| echor-onboarder, echor-updater, echor-consultador, echor-validator | echor-vault |

`caveman` is only injected into user-facing primaries (`orchestrator`, `strategist`).
`ponytail` is mandatory only for code writers and conditional for an `autonomous-small-fix` debugger task.
It is never injected into SDD, review, or infrastructure executors. `karpathy-guidelines`
is mandatory for orchestration, strategy, SDD, review, and debugging.

Never delegate to external Cavecrew agents (`cavecrew-builder`, `cavecrew-investigator`,
`cavecrew-reviewer`); route only to named harness agents. Cavecrew is external tooling,
distinct from the Caveman communication skill/plugin.

Conditional skills (`find-docs`, `refactoring-techniques`, `senior-architect`,
`software-design-patterns`, `event-schema`, `context-compact`, and `skill-registry`)
are injected only for roles and tasks listed in the registry. Judgment-day belongs only
to the orchestrator, never the judges. Runtime plugin activation is separate from this
delegation policy.

<br>

## Echor vault agents

`sub-agents/echor/` mirrors the four agents that maintain Echor, the Obsidian vault at `~/dev/echor` centralizing knowledge about the user's 100+ repos. All four load the shared `echor-vault` skill (vault paths, naming, frontmatter schema, read recipes, write rules) before doing any work.

| Agent | Role | Writes |
|---|---|---|
| echor-onboarder | Creates the vault entry for a repo that has none | `~/dev/echor/projects/<slug>/index.md`, `decisions.md` |
| echor-updater | Detects what changed and updates an existing index or appends a closed local decision | edits existing `index.md`, `decisions.md` |
| echor-consultador | Read-only query service over the vault | nothing, ever |
| echor-validator | Read-only consistency audit, vault versus real code | nothing, report only |

`echor-onboarder` and `echor-validator` share the same read-only Git and inspection allow-list (`git status*`, `git log*`, `git diff*`, `git show*`, `git rev-parse*`, `ls *`, `rg *`, `cat *`); `git commit*`/`git push*` are denied and `git reset --hard*` requires confirmation. `echor-updater` uses the same Bash allow-list but only `edit` (no `write`), since it only ever modifies an existing note. `echor-consultador` has no Bash access at all — `read`/`glob`/`grep` only, nothing else.

`/echor` (`commands/echor.md`, mirrored at `opencode/command/echor.md`) routes to the four agents by subcommand: `onboard <repo-path>`, `update <slug|all>`, `close <slug> <decision summary>`, `ask <question>`, `validate [slug|all]`.

<br>

## Enforcement of permissions (AUTH gates)

In OpenCode, permissions are granular per command via `opencode.json` (`allow`/`ask`/`deny` per agent). Claude Code has no equivalent native mechanism — there is no per-agent command allow-list built into the agent frontmatter beyond `tools`/`disallowedTools`. The gap is closed with `PreToolUse` hooks registered in `settings.json`.

`/home/andrex/.claude/hooks/infra-agent-bash-guard.py` is the reference implementation of this pattern. It intercepts `Bash` calls, keyed on `agent_type`, mirroring the role-scoped OpenCode policy. SDD agents are limited to documented `openspec` and read-only Git commands; prompt scope limits each artifact writer to its own file. Reviewers and judges can run tests, linters, and read-only Git without gaining open shell access.

| Agent | Allow | Ask | Deny |
|---|---|---|---|
| aws | `aws logs describe-*`, `aws dynamodb *`, `aws lambda get-*`/`list-*`, `aws ecs describe-*`/`list-*`, `aws ec2 describe-*`, `git *` | `git reset --hard*` | `git commit*`, `git push*` |
| log-reader | `rg *`, `wc *`, `du *`, `ls *`, `zcat *`, `gzip -cd *`, `journalctl *`, `docker logs *`, `kubectl logs *`, `git *` | `git reset --hard*` | `git commit*`, `git push*` |
| codegraph-maintainer | `codegraph status/query/explore/files/node/callers/callees/impact/affected`, `git *` | `git reset --hard*`, `codegraph unlock/init/sync/index*`, `codegraph-health*` | `git commit*`, `git push*` |
| engram-maintainer | `engram context/search/stats/projects list/doctor/timeline` | `engram delete *`, `engram export *` | all unrelated shell commands |
| code-reviewer | Scoped Node, Python, Java/Kotlin, Go, Rust, .NET, Ruby, PHP, and `make` test/lint/format-check/typecheck/compile/build/static-analysis commands; read-only Git | `git reset --hard*` | package install/update/sync/add/remove/publish, arbitrary scripts, shell chaining, other shell commands, `git commit*`, `git push*` |
| judge-a, judge-b | Same test/lint and read-only Git commands as `code-reviewer` | `git reset --hard*` | `git commit*`, `git push*` |
| sdd-explore | `openspec context`/`doctor`/`list` with `--store specter`, `openspec store list`, read-only Git; native `Write`/`Edit` for prompt-scoped `explore.md` | `git reset --hard*` | all other shell commands, `git commit*`, `git push*` |
| sdd-propose, sdd-spec, sdd-design, sdd-tasks | `openspec status`/`validate`/`show`/`new`/`instructions` with `--store specter`, `openspec store list`, read-only Git | `git reset --hard*` | all other shell commands, `git commit*`, `git push*` |
| sdd-verify | `openspec status`/`validate` with `--store specter`, `openspec store list`, reviewer test/lint, read-only Git; native `Write`/`Edit` for prompt-scoped `verify-report.md` | `git reset --hard*` | all other shell commands, `git commit*`, `git push*` |
| sdd-archive | `openspec status`/`validate`/`show`/`instructions`/`archive` with `--store specter`, `openspec store list`, read-only Git | `git reset --hard*` | all other shell commands, `git commit*`, `git push*` |
| echor-onboarder, echor-validator | Read-only Git (`status`/`log`/`diff`/`show`/`rev-parse`), `ls *`, `rg *`, `cat *` | `git reset --hard*` | all other shell commands, `git commit*`, `git push*` |
| echor-updater | Same read-only Git and inspection commands as `echor-onboarder` | `git reset --hard*` | all other shell commands, `git commit*`, `git push*` |
| echor-consultador | none | none | all shell commands |

Any command not matched by `allow` or `ask` falls through to `deny`. Any `agent_type` not in the `RULES` dict passes through untouched — the hook never affects the main thread or agents outside this list.

This is the pattern to reuse if another agent needs a Bash restriction in the future — for example, `test-writer` arguably should not touch production code paths. Today that boundary is prompt discipline only (documented in `test-writer`'s own instructions); no hook enforces it. This is a known gap, not yet addressed.

### `debugger` edit policy

`debugger` may apply any minimal fix when root cause, intended behavior, blast radius, and verification are clear and bounded; file count and change category alone do not require escalation. This includes a clear, verifiable localized environment or infrastructure configuration-variable correction. It escalates only uncertain behavior/root cause, broad or hard-to-predict impact, design/product/security trade-offs, migrations or other irreversible actions, or work that cannot be safely verified. `AUTH: diagnose-only` is an explicit investigation-only override: document root cause and proposed fix, but do not edit. Every diagnosis or fix reports root cause, exact files/changes, validation, and residual risk to the orchestrator.

Claude Code has no `Edit` `PreToolUse` matcher for `debugger`, so self-contained fixes do not ask permission solely because of agent type. OpenCode mirrors this with `debugger` `edit` and `write` permissions set to `"allow"`. Existing destructive-command confirmation and `git commit`/`git push` denial still apply.

<br>

## Circuit breaker

`tech-orchestrator.md`, "Validation and close" section: if `code-reviewer` reports the same BLOCKER on the same finding/file 3 times in a row, the orchestrator stops the reviewer-implementer cycle and escalates to the human instead of iterating further.

<br>

## Parity between Claude Code and OpenCode

Both mirrors (`/home/andrex/.claude/agents/` and `/home/andrex/.config/opencode/prompts/`) must stay behaviorally equivalent. Any change to an agent in one mirror must be replicated in the other.

This parity requirement is the origin of the recent cleanup pass reflected in this README: real contradictions had been found between the two mirrors (for example, diverging `sdd-spec` paths), since corrected by migrating both mirrors to the real `openspec` CLI archive flow described above.
