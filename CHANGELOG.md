# Changelog

## 0.2.0

- Capture first user prompt per session for context in the history table
- Use glob-based file discovery instead of hardcoded paths (works regardless of plugin data directory)
- Bump version for marketplace update

## 0.1.1

- Security hardening: cap stdin to 4KB, validate event types against allowlist, build JSON via `jq` to prevent injection, restrictive file permissions (600/700)
- Add marketplace manifest for plugin distribution
- Fix GitHub username in install instructions

## 0.1.0

- Initial release
- SessionStart/Stop hooks log session ID, timestamp, and working directory to JSONL
- `/session-journal:sessions` slash command to browse, filter, and resume sessions
- Human-readable JSONL format at `~/.claude/session-journal/session-history.jsonl`
