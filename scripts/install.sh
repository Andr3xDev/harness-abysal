#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_TARGETS=(
  "$HOME/.claude/agents"
  "$HOME/.claude/commands"
  "$HOME/.claude/skills"
  "$HOME/.claude/hooks"
  "$HOME/.claude/sounds"
  "$HOME/.claude/CLAUDE.md"
  "$HOME/.claude/settings.json"
  "$HOME/.claude/common-sdd.md"
  "$HOME/.claude/engram-protocol.md"
  "$HOME/.claude/rules/context7.md"
  "$HOME/.local/bin/codegraph-health"
  "$HOME/.claude.json"
  "$HOME/.config/opencode"
)

usage() {
  echo "usage: $0 [--clean-backups]"
}

clean_backups() {
  local target backup_dir found=false
  for target in "${BACKUP_TARGETS[@]}"; do
    backup_dir="${target}.backups"
    if [ -d "$backup_dir" ] && [ ! -L "$backup_dir" ]; then
      echo "removing $backup_dir"
      rm -rf "$backup_dir"
      found=true
    fi
  done
  "$found" || echo "no installer backups found"
}

case "$#" in
  0) ;;
  1)
    case "$1" in
      --clean-backups)
        clean_backups
        exit 0
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        usage >&2
        exit 1
        ;;
    esac
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

backup() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "${target}.backups"
    mv "$target" "${target}.backups/${STAMP}"
  fi
}

install_dir() {
  local source="$1"
  local target="$2"
  mkdir -p "$target"
  cp -a "$source/." "$target/"
}

install_file() {
  local source="$1"
  local target="$2"
  mkdir -p "$(dirname "$target")"
  backup "$target"
  cp "$source" "$target"
}

backup "$HOME/.claude/agents"
backup "$HOME/.claude/commands"
backup "$HOME/.claude/skills"
backup "$HOME/.claude/hooks"
backup "$HOME/.claude/sounds"
install_dir "$ROOT/agents" "$HOME/.claude/agents"
install_dir "$ROOT/commands" "$HOME/.claude/commands"
install_dir "$ROOT/skills" "$HOME/.claude/skills"
install_dir "$ROOT/hooks" "$HOME/.claude/hooks"
install_dir "$ROOT/sounds" "$HOME/.claude/sounds"
chmod +x "$HOME/.claude/hooks"/*.sh 2>/dev/null || true
install_file "$ROOT/configs/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
install_file "$ROOT/configs/claude-settings.json" "$HOME/.claude/settings.json"
install_file "$ROOT/configs/common-sdd.md" "$HOME/.claude/common-sdd.md"
install_file "$ROOT/configs/engram-protocol.md" "$HOME/.claude/engram-protocol.md"
mkdir -p "$HOME/.claude/rules"
install_file "$ROOT/configs/context7.md" "$HOME/.claude/rules/context7.md"
mkdir -p "$HOME/.local/bin"
install_file "$ROOT/scripts/codegraph-health.sh" "$HOME/.local/bin/codegraph-health"
chmod +x "$HOME/.local/bin/codegraph-health"

node - "$ROOT/configs/claude-mcp.json" "$HOME/.claude.json" "$STAMP" <<'NODE'
const fs = require('fs');
const [source, target, stamp] = process.argv.slice(2);
const mcpServers = JSON.parse(fs.readFileSync(source, 'utf8'));
const existing = fs.existsSync(target) ? fs.readFileSync(target, 'utf8') : null;
const config = existing === null ? {} : JSON.parse(existing);
config.mcpServers = { ...(config.mcpServers || {}), ...mcpServers };
if (existing !== null) {
  fs.mkdirSync(`${target}.backups`, { recursive: true });
  fs.renameSync(target, `${target}.backups/${stamp}`);
}
fs.writeFileSync(target, JSON.stringify(config, null, 2) + '\n');
NODE

backup "$HOME/.config/opencode"
mkdir -p "$HOME/.config/opencode"
tar \
  --exclude='./node_modules' \
  --exclude='./sessions' \
  --exclude='./cache' \
  --exclude='./logs' \
  -C "$ROOT/opencode" -cf - . | tar -C "$HOME/.config/opencode" -xf -

echo "installed code-agents config"
echo "next: set GITHUB_TOKEN, authenticate Linear/Claude connectors, ensure ~/.local/bin is in PATH, then run: claude doctor && opencode debug config"
