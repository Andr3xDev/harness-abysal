#!/usr/bin/env python3
"""PreToolUse guard for Bash calls made by read-only infrastructure subagents,
plus an Edit guard for the "debugger" agent.

The Bash guard mirrors the allow-lists already defined in
~/.config/opencode/opencode.json for restricted agents. Runs only against
tool_name == "Bash".
Any other agent_type (including the main thread, agent_type absent) is
passed through untouched -- this hook must never affect agents outside
this list.

The Edit guard is a separate, narrower rule: a PreToolUse hook only sees
tool_name and agent_type, never the AUTH (diagnose-only vs apply-fix) that
the orchestrator put in the debugger's delegation prompt -- that text is
invisible to the hook. Since the hook cannot tell which AUTH a given
Edit call was made under, it cannot conditionally block only the
diagnose-only case. Instead every Edit from the debugger agent requires
human confirmation ("ask"), regardless of AUTH -- this is a floor, not a
replacement for prompt discipline: apply-fix delegations still work (the
user just confirms), and diagnose-only delegations can no longer edit
production code silently.
"""
import fnmatch
import json
import sys

GIT_DENY = ["git commit*", "git push*"]
GIT_ASK = ["git reset --hard*"]
GIT_ALLOW = [
    "git status*",
    "git log*",
    "git diff*",
    "git show*",
    "git branch --list*",
    "git blame*",
]

SHELL_METACHARACTERS = ["&&", ";", "|", "$(", "`", "\n", ">", "<"]

RULES = {
    "sdd-explore": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": ["openspec context*", "openspec doctor*", "openspec list*"] + GIT_ALLOW,
    },
    "sdd-propose": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": ["openspec status*", "openspec validate*", "openspec show*", "openspec new*", "openspec instructions*"] + GIT_ALLOW,
    },
    "sdd-spec": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": ["openspec status*", "openspec validate*", "openspec show*", "openspec new*", "openspec instructions*"] + GIT_ALLOW,
    },
    "sdd-design": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": ["openspec status*", "openspec validate*", "openspec show*", "openspec new*", "openspec instructions*"] + GIT_ALLOW,
    },
    "sdd-tasks": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": ["openspec status*", "openspec validate*", "openspec show*", "openspec new*", "openspec instructions*"] + GIT_ALLOW,
    },
    "sdd-archive": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": ["openspec status*", "openspec validate*", "openspec archive*", "openspec show*", "openspec instructions*"] + GIT_ALLOW,
    },
    "aws": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": [
            "aws logs describe-*",
            "aws logs filter-log-events *",
            "aws logs get-log-events *",
            "aws logs start-query *",
            "aws logs get-query-results *",
            "aws dynamodb describe-*",
            "aws dynamodb list-*",
            "aws dynamodb get-item *",
            "aws dynamodb query *",
            "aws dynamodb scan *",
            "aws lambda get-*",
            "aws lambda list-*",
            "aws ecs describe-*",
            "aws ecs list-*",
            "aws ec2 describe-*",
        ] + GIT_ALLOW,
    },
    "log-reader": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": [
            "rg *",
            "wc *",
            "du *",
            "ls *",
            "zcat *",
            "gzip -cd *",
            "journalctl *",
            "docker logs *",
            "kubectl logs *",
        ] + GIT_ALLOW,
    },
    "codegraph-maintainer": {
        "deny": GIT_DENY,
        "ask": GIT_ASK + [
            "codegraph unlock*",
            "codegraph init*",
            "codegraph sync*",
            "codegraph index*",
            "codegraph-health*",
            "scripts/codegraph-health.sh*",
            "./scripts/codegraph-health.sh*",
        ],
        "allow": [
            "codegraph status*",
            "codegraph query*",
            "codegraph explore*",
            "codegraph files*",
            "codegraph node*",
            "codegraph callers*",
            "codegraph callees*",
            "codegraph impact*",
            "codegraph affected*",
        ] + GIT_ALLOW,
    },
    "engram-maintainer": {
        "deny": GIT_DENY,
        "ask": ["engram delete *", "engram export *"],
        "allow": [
            "engram context*",
            "engram search*",
            "engram stats*",
            "engram projects list*",
            "engram doctor*",
            "engram timeline*",
        ],
    },
    "code-reviewer": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": [
            "npm test*",
            "npm run test*",
            "npm run lint*",
            "yarn test*",
            "yarn lint*",
            "pnpm test*",
            "pnpm lint*",
            "pytest*",
            "python -m pytest*",
            "go test*",
            "go vet*",
            "cargo test*",
            "cargo clippy*",
            "ruff*",
            "eslint*",
            "flake8*",
            "mypy*",
            "rubocop*",
            "bundle exec rspec*",
            "mvn test*",
            "gradle test*",
            "make test*",
            "tox*",
        ] + GIT_ALLOW,
    },
    "echor-onboarder": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": GIT_ALLOW + ["git rev-parse*", "ls *", "rg *", "cat *"],
    },
    "echor-validator": {
        "deny": GIT_DENY,
        "ask": GIT_ASK,
        "allow": GIT_ALLOW + ["git rev-parse*", "ls *", "rg *", "cat *"],
    },
}

RULES["sdd-verify"] = {
    "deny": GIT_DENY,
    "ask": GIT_ASK,
    "allow": RULES["code-reviewer"]["allow"] + ["openspec status*", "openspec validate*"],
}
RULES["judge-a"] = RULES["code-reviewer"]
RULES["judge-b"] = RULES["code-reviewer"]
RULES["echor-updater"] = RULES["echor-onboarder"]


EDIT_ASK_AGENTS = {"debugger"}


def matches_any(command: str, patterns) -> bool:
    return any(fnmatch.fnmatchcase(command, p) for p in patterns)


def has_shell_metacharacters(command: str) -> bool:
    return any(token in command for token in SHELL_METACHARACTERS)


def decide_edit(agent_type: str):
    if agent_type not in EDIT_ASK_AGENTS:
        return None
    return "ask", (
        f"infra-agent-bash-guard: '{agent_type}' agent requires human "
        f"confirmation before any Edit. A PreToolUse hook cannot see the "
        f"AUTH (diagnose-only vs apply-fix) a delegation carried, so this "
        f"is enforced for every Edit regardless of AUTH -- confirm only "
        f"if this edit was actually authorized."
    )


def decide(agent_type: str, command: str):
    rules = RULES.get(agent_type)
    if rules is None:
        return None

    if has_shell_metacharacters(command):
        return "deny", (
            f"Blocked by infra-agent-bash-guard: '{agent_type}' agent is "
            f"read-only and command chaining/substitution characters "
            f"(&&, ;, |, $(), backticks, newlines, redirects) are not "
            f"permitted, regardless of allow-list matches."
        )

    if matches_any(command, rules["deny"]):
        return "deny", (
            f"Blocked by infra-agent-bash-guard: '{agent_type}' agent is "
            f"read-only; this command is on its explicit deny list "
            f"(git commit/push)."
        )
    if matches_any(command, rules["ask"]):
        return "ask", (
            f"infra-agent-bash-guard: '{agent_type}' agent requires "
            f"confirmation for this command."
        )
    if matches_any(command, rules["allow"]):
        return "allow", (
            f"infra-agent-bash-guard: command matches '{agent_type}' "
            f"read-only allow-list."
        )
    return "deny", (
        f"Blocked by infra-agent-bash-guard: '{agent_type}' agent is "
        f"restricted to a read-only command allow-list mirroring "
        f"opencode.json; this command is not on it."
    )


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    tool_name = payload.get("tool_name")
    agent_type = payload.get("agent_type")

    if tool_name == "Edit":
        result = decide_edit(agent_type)
    elif tool_name == "Bash":
        command = (payload.get("tool_input") or {}).get("command", "")
        result = decide(agent_type, command)
    else:
        return 0

    if result is None:
        return 0
    decision, reason = result

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }
    }))
    return 0


def _selftest() -> int:
    cases = [
        ("aws", "aws logs describe-log-groups && git push origin main", "deny"),
        ("codegraph-maintainer", "codegraph status && git commit -m pwned", "deny"),
        ("engram-maintainer", "engram context", "allow"),
        ("engram-maintainer", "engram delete 42", "ask"),
        ("engram-maintainer", "engram delete project demo --hard", "ask"),
        ("engram-maintainer", "engram export backup.json", "ask"),
        ("engram-maintainer", "engram save title text", "deny"),
        ("aws", "aws logs describe-log-groups", "allow"),
        ("code-reviewer", "npm test", "allow"),
        ("judge-a", "pytest", "allow"),
        ("sdd-explore", "openspec list --json", "allow"),
        ("sdd-propose", "npm test", "deny"),
        ("sdd-verify", "openspec validate change --json", "allow"),
        ("code-reviewer", "npm test && git push origin main", "deny"),
        ("echor-onboarder", "git rev-parse --short HEAD", "allow"),
        ("echor-onboarder", "rg -l lucyna /home/andrex/dev/some-repo", "allow"),
        ("echor-onboarder", "git commit -m x", "deny"),
        ("echor-updater", "ls /home/andrex/dev/echor/projects", "allow"),
        ("echor-validator", "git push origin main", "deny"),
    ]
    for agent_type, command, expected in cases:
        decision, _ = decide(agent_type, command)
        assert decision == expected, (
            f"FAIL: agent={agent_type!r} command={command!r} "
            f"expected={expected!r} got={decision!r}"
        )
        print(f"PASS: agent={agent_type!r} command={command!r} -> {decision!r}")

    edit_cases = [
        ("debugger", "ask"),
        ("aws", None),
        ("builder", None),
        (None, None),
    ]
    for agent_type, expected in edit_cases:
        result = decide_edit(agent_type)
        decision = result[0] if result else None
        assert decision == expected, (
            f"FAIL: edit agent={agent_type!r} expected={expected!r} "
            f"got={decision!r}"
        )
        print(f"PASS: edit agent={agent_type!r} -> {decision!r}")

    print("All self-test cases passed.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--selftest":
        sys.exit(_selftest())
    sys.exit(main())
