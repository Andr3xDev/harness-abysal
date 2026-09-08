#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT/scripts/smoke-install.sh"
"$ROOT/scripts/install.sh"
"$ROOT/scripts/install.sh" --clean-backups
