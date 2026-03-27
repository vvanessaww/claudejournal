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
/plugin marketplace add vanessawang/claudejournal
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

| # | Session ID | Started | Duration | Directory |
|---|-----------|---------|----------|-----------|
| 1 | abc-123   | 2026-03-25 14:30 | 45m | ~/myproject |
| 2 | def-456   | 2026-03-25 10:15 | 1h 20m | ~/work/api |

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

## Requirements

- Claude Code CLI
- `jq` (used by the logging script)

## License

MIT
