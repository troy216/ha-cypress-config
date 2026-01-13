# Save Session Report

Generate a session report summarizing this conversation's activities.

## Instructions

1. **Determine session name**: `YYYY-MM-DD-HHMM-<brief-summary>` using current date/time and a 2-4 word summary of the session's main focus.

2. **Check for existing session**: Look in `/config/history/` for a folder starting with today's date. If this session already has a report, update it instead of creating a new folder.

3. **Create session folder**: `/config/history/<session-name>/`

4. **Generate `report.md`** with standard detail (15-25 lines):
   ```markdown
   # Session Report: <summary>

   **Date:** YYYY-MM-DD HH:MM
   **Duration:** ~X minutes (estimated from conversation length)

   ## Summary
   2-3 sentences describing what was accomplished.

   ## Changes Made
   - path/to/file1 - brief description
   - path/to/file2 - brief description

   ## Key Decisions
   - Decision 1 with brief rationale
   - Decision 2 with brief rationale

   ## Notes
   Any issues encountered, follow-up items, or context for future sessions.
   ```

5. **For extensive changes**, create additional files:
   - `files-changed.md` - detailed list with diffs if helpful
   - `decisions.md` - extended discussion of key decisions

6. **Stage the report**: Run `git add /config/history/<session-name>/`

7. **Inform user**: Confirm report location and remind to commit when ready.

## Important
- Keep the main report.md brief and scannable
- Reference detail files rather than bloating the main report
- If updating an existing report, preserve previous content and append new activity
