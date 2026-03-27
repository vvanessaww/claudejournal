#!/usr/bin/env bash
# Logs session start/stop events to a JSONL file.
# Called by hooks with: log-session.sh <start|stop>
# Receives JSON on stdin with session_id from Claude Code.

set -euo pipefail

# Validate event type against allowlist
EVENT="${1:-unknown}"
case "$EVENT" in
  start|stop) ;;
  *) EVENT="unknown" ;;
esac

LOG_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/session-journal}"
LOG_FILE="${LOG_DIR}/session-history.jsonl"

# Create log directory with restrictive permissions
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

# Cap stdin to 4KB to prevent memory exhaustion
INPUT="$(head -c 4096)"

# Extract session_id safely via jq, falling back to "unknown"
SESSION_ID="$(jq -r '.session_id // "unknown"' <<< "$INPUT" 2>/dev/null || echo "unknown")"

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Build JSON safely using jq (prevents injection via session_id or cwd)
jq -cn \
  --arg session_id "$SESSION_ID" \
  --arg event "$EVENT" \
  --arg timestamp "$TIMESTAMP" \
  --arg cwd "$PWD" \
  '{session_id:$session_id,event:$event,timestamp:$timestamp,cwd:$cwd}' \
  >> "$LOG_FILE"

# Ensure log file is only readable by owner
chmod 600 "$LOG_FILE"
