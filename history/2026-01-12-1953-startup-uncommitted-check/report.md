# Session Report: Startup Uncommitted Check

**Date:** 2026-01-12 19:53
**Session ID:** 64bfdda6-11e1-4f26-9813-1942450dc7f6
**Duration:** ~20 minutes

## Summary

Session to enhance the Session Start directive with two new features:
1. Checking for uncommitted/unpushed changes at startup and correlating them with previous session reports to help users resume work
2. Discovering and implementing proper session ID tracking using Claude Code's internal session GUID

## Goals

- Add directive to check for uncommitted/unpushed git changes at session start
- If changes exist, look for related session reports in history folder
- Summarize pending work and ask user if they want to continue
- Implement session ID tracking to prevent accidentally updating reports from different sessions

## Changes Made

### `/config/CLAUDE.md`

**Session Start directive** (lines 30-42):

Added new checks and workflow for detecting pending work:

```markdown
### Session Start (on first user message)
- Before addressing the user's request, run startup checks:
  - Verify tools available; if missing, run `source /data/init-tools.sh`
  - Check GitHub: `git fetch origin && git log HEAD..origin/main --oneline`
  - Check for uncommitted changes: `git status --short`
  - Check for unpushed commits: `git log origin/main..HEAD --oneline`
- Report status briefly (e.g., "Tools ready. GitHub: no updates."), then address user's request
- If remote updates exist, describe the changes and ask if user wants to pull
- Do NOT automatically pull; local is authoritative unless user requests otherwise
- If local uncommitted/unpushed changes exist:
  - Look in `history/` for the most recent session report related to the changes
  - Summarize what the changes are and what was being worked on
  - Ask if user wants to continue that work or start fresh
```

### `/config/.claude/commands/save-session.md`

**Steps 2-3 updated** to use Claude Code's internal session ID:

```markdown
2. **Get current session ID**:
   ```bash
   ls -t "/data/home/.claude/projects/-config/"*.jsonl 2>/dev/null | head -1 | xargs basename | sed 's/.jsonl//'
   ```
   - This returns the Claude Code session GUID for the current conversation

3. **Check for existing session report**:
   - Search `history/` for a report.md containing this session ID
   - If found, update that report instead of creating a new folder
   - If not found, this is a new session - create a new folder
```

**Report template updated** to include Session ID field:
```markdown
**Date:** YYYY-MM-DD HH:MM
**Session ID:** <session-guid-from-step-2>
**Duration:** ~X minutes (estimated)
```

**Step numbers renumbered** from 7 steps to 8 steps to accommodate the new session ID steps.

## Key Decisions

### 1. Adding Uncommitted Change Detection
**Decision:** Check both `git status` and `git log origin/main..HEAD` at startup.

**Rationale:** These two commands together capture all pending work - both staged/unstaged changes and commits that haven't been pushed yet. This gives a complete picture of work in progress.

### 2. Using Claude Code's Internal Session ID
**Decision:** Use the session GUID from Claude Code's internal session files rather than generating a random UUID.

**Alternatives considered:**
- Generate random UUID at session start
- Use timestamp-based ID

**Rationale:** Claude Code already maintains session IDs in `/data/home/.claude/projects/-config/`. Using the real session GUID ensures consistency with the `/resume` command and provides a reliable way to identify which conversation created a report.

**Discovery:** Session files are stored as `<session-guid>.jsonl` files. The current session can be identified by finding the most recently modified `.jsonl` file:
```bash
ls -t "/data/home/.claude/projects/-config/"*.jsonl | head -1 | xargs basename | sed 's/.jsonl//'
```

## Technical Details

### Commands Run
```bash
# Startup checks
which git jq yq                           # Tools verified
git fetch origin                          # Fetch remote
git log HEAD..origin/main --oneline       # No remote updates

# Session ID discovery
env | grep -i session                     # No session env vars
ls -la /data/home/.claude/                # Found session-env directory
ls -la /data/home/.claude/projects/-config/  # Found session .jsonl files
ls -t "/data/home/.claude/projects/-config/"*.jsonl | head -1  # Current session file
```

### Session Storage Location
- Session files: `/data/home/.claude/projects/-config/<guid>.jsonl`
- Each conversation has a unique GUID
- Files are updated in real-time during the conversation

## Issues Encountered

1. [Issue 1: Incorrectly updated previous session report](issues/01-wrong-session-update.md) - Attempted to update a report from a different session instead of creating a new one

## Follow-up Items

### Completed This Session
- Added session ID to report format
- Updated `/save-session` command to use Claude Code's internal session ID
- Documented session ID discovery method

### Future Considerations
- Test the new startup directive in future sessions to verify it works correctly
- Verify session ID matching works for report updates
