#!/usr/bin/env bash
# Stop hook — forces Claude to keep working if criteria aren't met
# Exit 2 = keep working. Exit 0 = allow stop.
#
# This hook checks if there's a test runner available and if tests pass.
# If tests exist and fail, Claude can't declare "done".
# Lightweight by design — heavy verification goes in sdd-verify agent.

INPUT=$(cat)

# Check if we're in a project with tests
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "pytest.ini" ]; then
  # Python project — check pytest
  if command -v pytest &> /dev/null; then
    pytest --tb=no --no-header -q 2>/dev/null
    if [ $? -ne 0 ]; then
      echo "BLOCKED: tests are failing. Fix them before completing." >&2
      exit 2
    fi
  fi
elif [ -f "package.json" ]; then
  # Node project — check if test script exists
  if jq -e '.scripts.test' package.json &> /dev/null; then
    npm test --silent 2>/dev/null
    if [ $? -ne 0 ]; then
      echo "BLOCKED: tests are failing. Fix them before completing." >&2
      exit 2
    fi
  fi
fi

# Check linter if available
if command -v ruff &> /dev/null && [ -f "pyproject.toml" ]; then
  ruff check --quiet 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "BLOCKED: linter has errors. Fix them before completing." >&2
    exit 2
  fi
fi

exit 0
