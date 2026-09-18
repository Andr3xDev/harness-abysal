---
description: Plan a feature or change — propose, explore, spec, design, and break into tasks
---

Activate PLAN MODE for: $ARGUMENTS

Follow the orchestrator's plan mode workflow:
1. Detect working directory and project context
2. If "$ARGUMENTS" is a Linear/GitHub issue ID: read the issue first via MCP
3. Delegate to sdd-propose to create the OpenSpec change directory and proposal
4. Delegate to sdd-explore to persist exploration in that change directory
5. Present exploration summary — wait for human approval
6. Read the per-change `.openspec.yaml` before spec dispatch. If `skip_specs: true`, skip sdd-spec and use proposal/design acceptance scenarios; otherwise delegate to sdd-spec. Then delegate to sdd-design → sdd-tasks
7. Present the complete change folder for human review

Do NOT implement anything. Planning only.
