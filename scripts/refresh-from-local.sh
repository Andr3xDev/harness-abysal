#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUPS="$ROOT/.refresh-backups"
MANAGED_DIRS=(agents commands skills hooks opencode)
MANAGED_FILES=(configs/CLAUDE.md configs/claude-settings.json configs/common-sdd.md configs/engram-protocol.md configs/context7.md)

usage() {
  echo "usage: $0 [--restore <timestamp> | --clean-backups]"
}

copy_tree() {
  local source="$1" target="$2"
  [ -d "$source" ] || { echo "missing managed source: $source" >&2; exit 1; }
  rm -rf -- "$target"
  mkdir -p "$target"
  tar \
    --exclude='.git' --exclude='*/.git' \
    --exclude='__pycache__' --exclude='*/__pycache__' \
    --exclude='*.pyc' \
    --exclude='node_modules' --exclude='*/node_modules' \
    --exclude='sessions' --exclude='*/sessions' \
    --exclude='cache' --exclude='*/cache' \
    --exclude='logs' --exclude='*/logs' \
    --exclude='projects' --exclude='*/projects' \
    --exclude='paste-cache' --exclude='*/paste-cache' \
    --exclude='jobs' --exclude='*/jobs' \
    --exclude='statsig' --exclude='*/statsig' \
    --exclude='ide' --exclude='*/ide' \
    --exclude='shell-snapshots' --exclude='*/shell-snapshots' \
    --exclude='backups' --exclude='*/backups' \
    --exclude='plugins/cache' --exclude='*/plugins/cache' \
    --exclude='auth.json' --exclude='*/auth.json' \
    --exclude='credentials.json' --exclude='*/credentials.json' \
    --exclude='.env' --exclude='.env.*' --exclude='*/.env' --exclude='*/.env.*' \
    --exclude='*.pem' --exclude='*.key' \
    -C "$source" -cf - . | tar -C "$target" -xf -
}

copy_file() {
  local source="$1" target="$2"
  [ -f "$source" ] || { echo "missing managed source: $source" >&2; exit 1; }
  rm -f -- "$target"
  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
}

backup() {
  local stamp="$1" path
  umask 077
  for path in "${MANAGED_DIRS[@]}"; do
    [ -e "$ROOT/$path" ] && copy_tree "$ROOT/$path" "$BACKUPS/$stamp/$path"
  done
  for path in "${MANAGED_FILES[@]}"; do
    [ -e "$ROOT/$path" ] && copy_file "$ROOT/$path" "$BACKUPS/$stamp/$path"
  done
}

refresh() {
  local stamp path
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  while [ -e "$BACKUPS/$stamp" ]; do stamp="${stamp}-1"; done
  backup "$stamp"

  copy_tree "$HOME/.claude/agents" "$ROOT/agents"
  copy_tree "$HOME/.claude/commands" "$ROOT/commands"
  copy_tree "$HOME/.claude/skills" "$ROOT/skills"
  copy_tree "$HOME/.claude/hooks" "$ROOT/hooks"
  copy_file "$HOME/.claude/CLAUDE.md" "$ROOT/configs/CLAUDE.md"
  copy_file "$HOME/.claude/settings.json" "$ROOT/configs/claude-settings.json"
  copy_file "$HOME/.claude/common-sdd.md" "$ROOT/configs/common-sdd.md"
  copy_file "$HOME/.claude/engram-protocol.md" "$ROOT/configs/engram-protocol.md"
  copy_file "$HOME/.claude/rules/context7.md" "$ROOT/configs/context7.md"
  copy_tree "$HOME/.config/opencode" "$ROOT/opencode"
  find "$ROOT" -name .DS_Store -delete
  echo "refreshed managed config; backup: .refresh-backups/$stamp"
}

restore() {
  local stamp="$1" path source="$BACKUPS/$1"
  [ -d "$source" ] || { echo "backup not found: $stamp" >&2; exit 1; }
  for path in "${MANAGED_DIRS[@]}"; do
    rm -rf -- "$ROOT/$path"
    [ -d "$source/$path" ] && copy_tree "$source/$path" "$ROOT/$path"
  done
  for path in "${MANAGED_FILES[@]}"; do
    rm -f -- "$ROOT/$path"
    [ -f "$source/$path" ] && copy_file "$source/$path" "$ROOT/$path"
  done
  echo "restored managed config from .refresh-backups/$stamp"
}

case "${1:-}" in
  "") refresh ;;
  --restore) [ "$#" = 2 ] || { usage >&2; exit 1; }; restore "$2" ;;
  --clean-backups) [ "$#" = 1 ] || { usage >&2; exit 1; }; rm -rf -- "$BACKUPS"; echo "removed .refresh-backups" ;;
  --help|-h) usage ;;
  *) usage >&2; exit 1 ;;
esac
