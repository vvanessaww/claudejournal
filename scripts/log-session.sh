#!/usr/bin/env bash
# Logs session start/stop events to a JSONL file.
# Called by hooks with: log-session.sh <start|stop>
# Receives JSON on stdin with session_id from Claude Code.

set -euo pipefail

EVENT="${1:-unknown}"
LOG_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/session-journal}"
LOG_FILE="${LOG_DIR}/session-history.jsonl"

mkdir -p "$LOG_DIR"

jq -c -r \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg cwd "$PWD" \
  --arg event "$EVENT" \
  '{session_id: .session_id, event: $event, timestamp: $ts, cwd: $cwd}' \
  >> "$LOG_FILE"
