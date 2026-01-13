# Issue: Cross-Contamination and Multi-File Matching

## What Happened

During thorough testing of the session identification script, discovered that markers can appear in multiple session JSONL files. This caused the script to potentially return the wrong session.

**Scenario:**
1. Session A generates marker `SESS-aaa...`
2. Session B (current) mentions Session A's marker in conversation
3. Searching for `SESS-aaa...` now finds BOTH session files
4. Original script used `head -1` which returned whichever file grep found first (non-deterministic)

## Impact

- Script could return wrong session ID
- Session reports could be saved to wrong session's folder
- In concurrent environments, this would cause cross-session contamination

## Root Cause

**Design oversight:** The original implementation assumed each marker would only exist in one file. However:
1. JSONL files record ALL conversation output
2. Mentioning another session's marker (even in testing) causes it to appear in the current session's JSONL
3. `grep -rl | head -1` provides no guarantee about which matching file is selected

## Resolution

Modified the script to sort matching files by modification time (newest first) using `stat`:

```bash
JSONL_FILE=$(echo "$MATCHING_FILES" | while read -r f; do
  mtime=$(stat -c '%Y' "$f" 2>/dev/null)
  echo "$mtime $f"
done | sort -rn | head -1 | cut -d' ' -f2-)
```

**Rationale:** The current active session's JSONL file is always the most recently modified (it's being written to as we speak). Old sessions that happen to contain the same text will have older timestamps.

## Improvements

**For Claude:**
- When implementing file search logic, consider what happens when patterns appear in multiple files
- Always test with cross-contamination scenarios (data appearing in unexpected places)
- Don't assume uniqueness without verification

**For System:**
- The "most recently modified" heuristic is robust but could be documented more explicitly
- Consider adding a warning when multiple files match (for debugging)
