#!/usr/bin/env bash
# Tests for log-session.sh
# Run: bash tests/test-log-session.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# Create a temp directory for each test run
setup() {
  TEST_DIR="$(mktemp -d)"
  export CLAUDE_PLUGIN_DATA="$TEST_DIR"
  LOG_FILE="$TEST_DIR/session-history.jsonl"
}

teardown() {
  rm -rf "$TEST_DIR"
}

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label"
    echo "    expected to contain: $needle"
    echo "    actual: $haystack"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  local label="$1" path="$2"
  if [ -f "$path" ]; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label (file not found: $path)"
    FAIL=$((FAIL + 1))
  fi
}

# --- Tests ---

echo "=== log-session.sh ==="

echo "test: start event creates log entry"
setup
echo '{"session_id":"test-123"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
assert_file_exists "log file created" "$LOG_FILE"
LINE="$(cat "$LOG_FILE")"
assert_contains "has session_id" '"session_id":"test-123"' "$LINE"
assert_contains "has event start" '"event":"start"' "$LINE"
assert_contains "has timestamp" '"timestamp":' "$LINE"
assert_contains "has cwd" '"cwd":' "$LINE"
teardown

echo "test: stop event creates log entry"
setup
echo '{"session_id":"test-456"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" stop
LINE="$(cat "$LOG_FILE")"
assert_contains "has event stop" '"event":"stop"' "$LINE"
assert_contains "has session_id" '"session_id":"test-456"' "$LINE"
teardown

echo "test: invalid event type defaults to unknown"
setup
echo '{"session_id":"test-789"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" badtype
LINE="$(cat "$LOG_FILE")"
assert_contains "event is unknown" '"event":"unknown"' "$LINE"
teardown

echo "test: missing session_id defaults to unknown"
setup
echo '{}' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
LINE="$(cat "$LOG_FILE")"
assert_contains "session_id is unknown" '"session_id":"unknown"' "$LINE"
teardown

echo "test: malformed JSON input defaults to unknown session_id"
setup
echo 'not json at all' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
LINE="$(cat "$LOG_FILE")"
assert_contains "session_id falls back to unknown" '"session_id":"unknown"' "$LINE"
teardown

echo "test: log directory has restrictive permissions"
setup
echo '{"session_id":"test-perm"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
PERMS="$(stat -f '%Lp' "$TEST_DIR" 2>/dev/null || stat -c '%a' "$TEST_DIR" 2>/dev/null)"
assert_eq "directory permissions are 700" "700" "$PERMS"
teardown

echo "test: log file has restrictive permissions"
setup
echo '{"session_id":"test-perm2"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
PERMS="$(stat -f '%Lp' "$LOG_FILE" 2>/dev/null || stat -c '%a' "$LOG_FILE" 2>/dev/null)"
assert_eq "file permissions are 600" "600" "$PERMS"
teardown

echo "test: multiple entries append correctly"
setup
echo '{"session_id":"sess-1"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
echo '{"session_id":"sess-2"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
LINES="$(wc -l < "$LOG_FILE" | tr -d ' ')"
assert_eq "two lines in log" "2" "$LINES"
teardown

echo ""
echo "=== log-prompt.sh ==="

echo "test: captures first prompt"
setup
# Need a start event first so the file exists
echo '{"session_id":"prompt-test"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
echo '{"session_id":"prompt-test","user_message":"hello world"}' | bash "$SCRIPT_DIR/scripts/log-prompt.sh"
PROMPT_LINE="$(grep '"event":"prompt"' "$LOG_FILE")"
assert_contains "has prompt event" '"event":"prompt"' "$PROMPT_LINE"
assert_contains "has prompt text" '"prompt":"hello world"' "$PROMPT_LINE"
teardown

echo "test: skips duplicate prompts for same session"
setup
echo '{"session_id":"dup-test"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
echo '{"session_id":"dup-test","user_message":"first prompt"}' | bash "$SCRIPT_DIR/scripts/log-prompt.sh"
echo '{"session_id":"dup-test","user_message":"second prompt"}' | bash "$SCRIPT_DIR/scripts/log-prompt.sh"
PROMPT_COUNT="$(grep -c '"event":"prompt"' "$LOG_FILE")"
assert_eq "only one prompt logged" "1" "$PROMPT_COUNT"
teardown

echo "test: different sessions get separate prompts"
setup
echo '{"session_id":"multi-1"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
echo '{"session_id":"multi-1","user_message":"prompt one"}' | bash "$SCRIPT_DIR/scripts/log-prompt.sh"
echo '{"session_id":"multi-2"}' | bash "$SCRIPT_DIR/scripts/log-session.sh" start
echo '{"session_id":"multi-2","user_message":"prompt two"}' | bash "$SCRIPT_DIR/scripts/log-prompt.sh"
PROMPT_COUNT="$(grep -c '"event":"prompt"' "$LOG_FILE")"
assert_eq "two prompts logged for two sessions" "2" "$PROMPT_COUNT"
teardown

echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
