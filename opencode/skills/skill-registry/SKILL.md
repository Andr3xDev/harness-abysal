---
name: skill-registry
description: "Trigger: update skills, skill registry, refresh skills, after skill changes. Index available skills by trigger and path."
license: MIT
metadata:
  author: custom
  version: "1.0"
---

## Activation Contract

Use this skill after installing, removing, creating, moving, or renaming skills.
Also use when the orchestrator needs a fresh skill index for delegation.

## Hard Rules

- The registry is an INDEX, not a compiler. SKILL.md remains the source of truth.
- Pass exact skill paths to subagents — never generated summaries.
- Always write the registry file regardless of persistence mode.
- Save to Engram as `topic_key: skill-registry` when available.
- Skip `_shared` directory entries — those are conventions, not skills.
- Deduplicate by skill name, preferring project-level skills over global.

## Decision Gates

| Situation | Action |
|---|---|
| Same skill exists globally and in project | Keep the project-level skill |
| No skills found | Write an empty registry so agents stop searching blindly |
| Orchestrator will delegate work | Look up the target agent in the Mandatory Skill Assignments table, then check the Conditional Skill Triggers table for keyword matches in the task text. Inject only these — never "select what seems relevant" |
| Skill modified or added | Re-run this skill to refresh the index |

## Mandatory Skill Assignments (static, per agent role)

This table is the single source of truth for `ponytail` vs `karpathy-guidelines` assignment.
Do not load both on the same agent. Do not load either on agents not listed.

| Agent | Mandatory skills (always injected) |
|---|---|
| builder | ponytail |
| implementer | ponytail |
| test-writer | ponytail |
| sdd-explore | karpathy-guidelines |
| sdd-propose | karpathy-guidelines |
| sdd-spec | karpathy-guidelines |
| sdd-design | karpathy-guidelines |
| sdd-tasks | karpathy-guidelines |
| sdd-verify | karpathy-guidelines |
| sdd-archive | karpathy-guidelines |
| code-reviewer | karpathy-guidelines |
| judge-a | karpathy-guidelines |
| judge-b | karpathy-guidelines |
| strategist | karpathy-guidelines |
| aws | none — read-only infrastructure, no code written, no feature planned |
| log-reader | none — read-only infrastructure, no code written, no feature planned |
| codegraph-maintainer | none — read-only infrastructure, no code written, no feature planned |

Agents not listed here (e.g. `debugger`) keep their current skill configuration until
explicitly audited and added to this table — do not infer a row for them.

## Conditional Skill Triggers (static, per agent, exact keywords)

Inject the skill only when the task text contains one of its listed keywords.

| Agent | Conditional skill | Trigger keywords |
|---|---|---|
| builder | find-docs | library, API, SDK, CLI tool, cloud service, "how do I" + library name, version migration, setup instructions |
| builder | md-style-guide | markdown document, report, guide, README, format/clean up/rewrite an existing markdown file |
| builder | refactoring-techniques | refactor |
| builder | senior-architect | architecture patterns, system design, database selection, tech stack evaluation, dependency analysis, trade-off comparisons |
| builder | software-design-patterns | which design pattern to use, understand a specific pattern, identify the right pattern for a problem |
| builder | event-schema | domain event, event schema, event-driven, emits event |
| implementer | find-docs | library, API, SDK, CLI tool, cloud service, "how do I" + library name, version migration, setup instructions |
| implementer | refactoring-techniques | refactor |
| implementer | event-schema | domain event, event schema, event-driven, emits event |
| test-writer | find-docs | library, API, SDK, CLI tool, cloud service, "how do I" + library name, version migration, setup instructions |
| test-writer | event-schema | domain event, event schema, event-driven, emits event |
| code-reviewer | refactoring-techniques | refactor |
| code-reviewer | event-schema | domain event, event schema, event-driven, emits event |
| code-reviewer | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| sdd-explore | find-docs | library, API, SDK, CLI tool, cloud service, "how do I" + library name, version migration, setup instructions |
| sdd-explore | senior-architect | architecture patterns, system design, database selection, tech stack evaluation, dependency analysis, trade-off comparisons |
| sdd-explore | software-design-patterns | which design pattern to use, understand a specific pattern, identify the right pattern for a problem |
| sdd-explore | event-schema | domain event, event schema, event-driven, emits event |
| sdd-explore | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| sdd-propose | md-style-guide | markdown document, report, guide, README, format/clean up/rewrite an existing markdown file |
| sdd-propose | senior-architect | architecture patterns, system design, database selection, tech stack evaluation, dependency analysis, trade-off comparisons |
| sdd-propose | event-schema | domain event, event schema, event-driven, emits event |
| sdd-propose | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| sdd-spec | md-style-guide | markdown document, report, guide, README, format/clean up/rewrite an existing markdown file |
| sdd-spec | event-schema | domain event, event schema, event-driven, emits event |
| sdd-spec | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| sdd-design | find-docs | library, API, SDK, CLI tool, cloud service, "how do I" + library name, version migration, setup instructions |
| sdd-design | md-style-guide | markdown document, report, guide, README, format/clean up/rewrite an existing markdown file |
| sdd-design | senior-architect | architecture patterns, system design, database selection, tech stack evaluation, dependency analysis, trade-off comparisons |
| sdd-design | software-design-patterns | which design pattern to use, understand a specific pattern, identify the right pattern for a problem |
| sdd-design | event-schema | domain event, event schema, event-driven, emits event |
| sdd-design | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| sdd-tasks | md-style-guide | markdown document, report, guide, README, format/clean up/rewrite an existing markdown file |
| sdd-tasks | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| sdd-verify | event-schema | domain event, event schema, event-driven, emits event |
| sdd-verify | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| sdd-archive | md-style-guide | markdown document, report, guide, README, format/clean up/rewrite an existing markdown file |
| sdd-archive | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| strategist | senior-architect | architecture patterns, system design, database selection, tech stack evaluation, dependency analysis, trade-off comparisons |
| strategist | software-design-patterns | which design pattern to use, understand a specific pattern, identify the right pattern for a problem |
| strategist | event-schema | domain event, event schema, event-driven, emits event |
| strategist | md-style-guide | markdown document, report, guide, README, format/clean up/rewrite an existing markdown file |
| strategist | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| aws | find-docs | library, API, SDK, CLI tool, cloud service, "how do I" + library name, version migration, setup instructions |
| judge-a | judgment-day | judgment day, dual review, adversarial review |
| judge-a | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| judge-b | judgment-day | judgment day, dual review, adversarial review |
| judge-b | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |
| debugger | ponytail | simplify, over-engineered, simpler alternative, YAGNI, less code, unnecessarily complex |

`log-reader` and `codegraph-maintainer` have no conditional skills — keep them free of skill
injection beyond `caveman` unless this table is explicitly updated.

## Execution Steps

1. Scan skill directories for `*/SKILL.md`:
   - `~/.config/opencode/skills/` (global)
   - `{project}/.opencode/skills/` (project-level, if exists)
2. Read frontmatter only — extract `name` and `description` trigger text.
3. Write `.opencode/skill-registry.md` with:
   ```
   # Skill Registry

   | Skill | Trigger | Scope | Path |
   |-------|---------|-------|------|
   | context-compact | compact, clear, context reset | global | ~/.config/opencode/skills/context-compact/SKILL.md |
   | event-schema | domain event, event schema | global | ~/.config/opencode/skills/event-schema/SKILL.md |
   ```
4. Persist to Engram:
   ```
   title: "skill-registry"
   topic_key: "skill-registry"
   type: "config"
   content: {registry markdown}
   ```
5. Return registry path, skill count, and cache status.

## Output Contract

Return:
- Registry file path
- Number of indexed skills
- Any skipped or duplicate skills
