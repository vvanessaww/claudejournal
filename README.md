# session-journal

A Claude Code plugin that automatically logs every session ID, timestamp, and working directory so you never lose a conversation.

## The problem

When you close Claude Code (especially without Ctrl-C), the session ID disappears. If you didn't note it down, that conversation is gone. This plugin silently records every session so you can always go back.

## What it does

- **SessionStart hook** -- logs session ID, timestamp, and working directory
- **Stop hook** -- logs when the session ends so you get duration
- **`/session-journal:sessions`** -- slash command to browse your history and find sessions to resume

All data is stored as JSONL at `~/.claude/plugins/data/session-journal/session-history.jsonl`.

## Install

### From GitHub

```bash
# Inside Claude Code:
/plugin marketplace add vvanessaww/claudejournal
/plugin install session-journal
```

### Local testing

```bash
claude --plugin-dir /path/to/claudejournal
```

## Usage

### Browse sessions

Type inside Claude Code:

```
/session-journal:sessions
```

This shows a table of your recent sessions sorted newest-first:

```
 #  Session ID       Started              Duration  Directory            First Prompt
 1  a1b2c3d4e5f6...  2026-03-28 22:53     45m       ~/myproject          help me set up auth...
 2  f7e8d9c0b1a2...  2026-03-28 18:10     1h 20m    ~/work/api           fix the rate limiti...
 3  d4c3b2a1e5f6...  2026-03-27 14:30     2h 5m     ~/side-project       add dark mode toggle
 4  b9a8c7d6e5f4...  2026-03-27 09:00     active     ~/work/api           —
```

### Filter by project

```
/session-journal:sessions myproject
```

### Resume a session

```bash
claude --resume <session_id>
```

### View raw log

```bash
cat ~/.claude/plugins/data/session-journal/session-history.jsonl | jq .
```

## Log format

Each line in the JSONL file looks like:

```json
{"session_id":"abc-123","event":"start","timestamp":"2026-03-25T14:30:00Z","cwd":"/Users/you/myproject"}
{"session_id":"abc-123","event":"stop","timestamp":"2026-03-25T15:15:00Z","cwd":"/Users/you/myproject"}
```

## How is this different from `/resume`?

Claude Code has a built-in `/resume` command that shows recent sessions. So why do you need this?

| | `/resume` (built-in) | `session-journal` (this plugin) |
|---|---|---|
| Needs session ID upfront | Shows recent list | Full searchable history |
| Survives terminal crash/close | Transcript may be lost | Log entry written at session start |
| Searchable by project directory | No | Yes (`/session-journal:sessions myproject`) |
| Tracks session duration | No | Yes (start + stop timestamps) |
| Survives transcript cleanup | No (respects `cleanupPeriodDays`) | Yes (independent log file) |
| Data format | Opaque internal transcripts | Human-readable JSONL you own |

**`/resume` is the mechanism to go back. `session-journal` is the index that tells you where to go back *to*.**

Without this plugin, you're relying on memory or scrolling terminal history to find a session ID. With it, you can grep by project, date, or just scan recent sessions.

## Requirements

- Claude Code CLI
- `jq` (used by the logging scripts for safe JSON construction)

## Troubleshooting

**No sessions showing up?**
Sessions are logged by hooks that fire on SessionStart/Stop. If you just installed the plugin, you won't see any history yet -- start a new Claude Code session and it'll appear.

**`jq: command not found`**
The logging scripts use `jq` to safely construct JSON (prevents injection via malformed session IDs). Install it:
- macOS: `brew install jq`
- Ubuntu/Debian: `sudo apt install jq`
- Other: [stedolan.github.io/jq/download](https://stedolan.github.io/jq/download/)

**Log file location**
The JSONL file lives at `~/.claude/session-journal/session-history.jsonl` by default, or under `$CLAUDE_PLUGIN_DATA` if that's set. The `/session-journal:sessions` command uses glob to find it regardless of exact path.

**Permission errors**
The scripts create the log directory with `700` and the log file with `600` permissions (owner-only). If you're getting permission errors, check that `~/.claude/` is owned by your user.

## Tests

```bash
bash tests/test-log-session.sh
```

## License

MIT
