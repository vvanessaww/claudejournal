#!/usr/bin/env bash
# Logs the first user prompt per session for context.
# Called by UserPromptSubmit hook.
# Receives JSON on stdin with session_id and user prompt content.

set -euo pipefail

LOG_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/session-journal}"
LOG_FILE="${LOG_DIR}/session-history.jsonl"

mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

# Cap stdin to 4KB
INPUT="$(head -c 4096)"

SESSION_ID="$(jq -r '.session_id // "unknown"' <<< "$INPUT" 2>/dev/null || echo "unknown")"

# Only log the first prompt per session (skip if we already have one)
if grep -F "\"session_id\":\"${SESSION_ID}\"" "$LOG_FILE" 2>/dev/null | grep -qF "\"event\":\"prompt\""; then
  exit 0
fi

# Extract the user's message -- try common field names
PROMPT="$(jq -r '(.user_message // .message // .content // .prompt // .input // "") | tostring | .[0:200]' <<< "$INPUT" 2>/dev/null || echo "")"

# If no message found, try to grab the full input as a fallback for debugging
if [ -z "$PROMPT" ] || [ "$PROMPT" = "null" ]; then
  PROMPT="$(jq -r 'keys | join(",")' <<< "$INPUT" 2>/dev/null || echo "(no prompt captured)")"
  PROMPT="[fields: $PROMPT]"
fi

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -cn \
  --arg session_id "$SESSION_ID" \
  --arg event "prompt" \
  --arg timestamp "$TIMESTAMP" \
  --arg cwd "$PWD" \
  --arg prompt "$PROMPT" \
  '{session_id:$session_id,event:$event,timestamp:$timestamp,cwd:$cwd,prompt:$prompt}' \
  >> "$LOG_FILE"

chmod 600 "$LOG_FILE"
