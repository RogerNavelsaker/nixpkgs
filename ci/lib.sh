#!/usr/bin/env bash
# Shared helpers for ci/*.sh. Source from the caller repo root. Requires jq.
SYNC_CONFIG="${SYNC_CONFIG:-.nixpkg-sync.json}"

cfg() { jq -r --arg k "$1" '.[$k] // empty' "$SYNC_CONFIG"; }
cfg_list() { jq -r --arg k "$1" '(.[$k] // [])[]' "$SYNC_CONFIG"; }

# Print the pinned/manifest version for a worktree ref ("" = working tree).
read_version() {
  local ref=${1:-} file jq_expr grep_expr content
  file=$(cfg version_file); jq_expr=$(cfg version_jq); grep_expr=$(cfg version_grep)
  [ -n "$file" ] || return 1
  if [ -n "$ref" ]; then content=$(git show "$ref:$file" 2>/dev/null) || return 1
  else content=$(cat "$file" 2>/dev/null) || return 1; fi
  if [ -n "$jq_expr" ]; then printf '%s' "$content" | jq -r "$jq_expr" 2>/dev/null
  elif [ -n "$grep_expr" ]; then printf '%s' "$content" | grep -oE "$grep_expr" | head -n1 | sed -E 's/.*"([^"]+)".*/\1/'
  else return 1; fi
}
