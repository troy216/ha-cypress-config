# Session Report: Robust Session Identification

**Date:** 2026-01-12 23:58
**Session ID:** f2eaf04f-2eea-4a66-a24b-1b39528e15fc
**Duration:** ~25 minutes

## Summary

Implemented a robust session identification system to solve the race condition problem when running concurrent Claude sessions. The previous approach relied on "most recently modified JSONL file" which could incorrectly identify the session in concurrent environments. The new system generates a unique marker at session start, which gets recorded in the JSONL, enabling definitive session matching via grep.

## Goals

- Understand how session IDs were being determined (user asked about the process)
- Identify the flaw in the current approach (race condition with concurrent sessions)
- Implement a robust solution using unique session markers
- Update documentation and the save-session command to use the new approach

## Changes Made

### `/data/scripts/find-session.sh` (Created)
Script to find session UUID by searching for a unique marker in JSONL files.

**Key features:**
- Accepts a marker string and searches all JSONL files
- Returns the session UUID from matching file
- `--report` flag returns the history report folder path if it exists
- Proper error handling and usage messages

```bash
# Usage examples
/data/scripts/find-session.sh SESS-7f3a9c2b1e4d        # Returns UUID
/data/scripts/find-session.sh SESS-7f3a9c2b1e4d --report  # Returns report folder
```

### `/config/CLAUDE.md` (Updated)
- Added session marker generation to Session Start directives
- Added new "Session Identification" section explaining the marker system
- Updated status output format to include marker

### `/config/.claude/commands/save-session.md` (Updated)
- Replaced the `ls -t | head -1` approach with marker-based lookup
- Updated steps 2 and 3 to use `/data/scripts/find-session.sh`

## Key Decisions

### Decision: Use conversation-embedded markers
**Alternatives considered:**
1. File-based marker storage (`/tmp/` or `/data/`)
2. Environment variables
3. Rely on existing Claude Code slug field

**Rationale:** Embedding the marker in the conversation output is simplest and most reliable. It automatically gets recorded to JSONL, requires no additional storage, and survives container restarts (the marker is in the JSONL history).

### Decision: Marker format `SESS-xxxxxxxxxxxx`
**Format:** `SESS-` prefix + 12 hex chars from SHA256 of nanosecond timestamp
**Rationale:** Short enough to include in status line, unique enough to avoid collisions, easily recognizable pattern for grep.

### Decision: Include marker in startup status line
**Rationale:** User wanted minimal visibility impact. Integrating into existing status output (e.g., "Tools ready. GitHub synced. [SESS-7f3a9c2b1e4d]") keeps it unobtrusive.

## Technical Details

### Marker Generation
```bash
SESS-$(date +%s%N | sha256sum | head -c 12)
```
Uses nanosecond timestamp hashed with SHA256, taking first 12 hex characters.

### Session Lookup Flow
1. At session start: generate and output marker
2. Marker gets written to JSONL by Claude Code
3. When saving: grep JSONL files for marker
4. Extract sessionId from matching file
5. Use sessionId to find/create history report

### JSONL Structure Discovery
Explored `/data/home/.claude/projects/-config/` structure:
- Sessions stored in UUID-named directories
- JSONL files contain `sessionId` field in every entry
- Also contain `slug` field (human-readable session name)

## Issues Encountered

- [Issue 1: Initial misunderstanding of session ID source](issues/01-session-id-assumption.md)

## Follow-up Items

- Test with actual concurrent sessions to verify robustness
- Consider adding marker to session report header for easier manual identification
- The old save-session.md instructions (in the skill prompt shown to user) still show the old approach - this will be updated when the skill file is reloaded
