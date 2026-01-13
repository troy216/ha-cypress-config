# Issue: Incorrectly Updated Previous Session Report

## What Happened

When running `/save-session`, I found an existing session folder from today (`2026-01-12-1933-directive-clarifications`) and assumed it was from the current session. I began updating that report instead of creating a new one.

The user had to interrupt and explain that this was a new session, not a continuation of the previous one.

## Impact

- Modified an already-committed session report incorrectly
- Required reversion of the change
- Brief confusion about session boundaries

## Root Cause

**Claude assumption error**: The `/save-session` command instructed to look for existing session folders from today and update them if found. However, I had no way to distinguish between:
1. A previous save from the current conversation (should update)
2. A report from a completely different session earlier today (should not update)

The instruction "If this session already has a report, update it" is ambiguous without a session identifier.

## Resolution

1. Reverted the change to the previous session's report
2. Created a new session folder: `2026-01-12-1953-startup-uncommitted-check`
3. User suggested adding session IDs to reports

## Improvements

### For Claude
- Don't assume same-day reports are from the current session
- Look for explicit session continuity markers before updating

### For System
- **Add session ID to reports**: Generate a unique ID at the start of each session and include it in reports
- **Update `/save-session` command**: Only update an existing report if the session ID matches one previously used in the current conversation
- **Store session ID in conversation**: When creating a report, note the session ID so subsequent saves know to update it

### Proposed Session ID Format
```markdown
**Session ID:** <8-char-uuid>
```

This allows Claude to:
1. Generate a new ID when creating a fresh report
2. Remember the ID within the conversation
3. Only update reports with matching IDs
