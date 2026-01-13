#!/bin/bash
# find-session.sh - Find session UUID by searching for a unique marker in JSONL files
#
# Usage:
#   find-session.sh <marker>           - Returns the session UUID
#   find-session.sh <marker> --report  - Returns the history report folder path (if exists)
#
# Example:
#   find-session.sh SESS-7f3a9c2b1e4d
#   find-session.sh SESS-7f3a9c2b1e4d --report

MARKER="$1"
MODE="$2"
JSONL_DIR="/data/home/.claude/projects/-config"
HISTORY_DIR="/config/history"

if [ -z "$MARKER" ]; then
  echo "Usage: $0 <marker> [--report]" >&2
  echo "  <marker>   Session marker (e.g., SESS-7f3a9c2b1e4d)" >&2
  echo "  --report   Also return the history report folder path" >&2
  exit 1
fi

# Find JSONL files containing the marker (search recursively)
# Use most recently modified file if multiple match (current session is most recent)
MATCHING_FILES=$(grep -rl "$MARKER" "$JSONL_DIR" 2>/dev/null)

if [ -z "$MATCHING_FILES" ]; then
  echo "ERROR: Marker '$MARKER' not found in any session file" >&2
  exit 1
fi

# Sort by modification time (newest first) and take the first
# Use stat to get epoch time, sort numerically, take newest
JSONL_FILE=$(echo "$MATCHING_FILES" | while read -r f; do
  mtime=$(stat -c '%Y' "$f" 2>/dev/null)
  echo "$mtime $f"
done | sort -rn | head -1 | cut -d' ' -f2-)

if [ -z "$JSONL_FILE" ]; then
  echo "ERROR: Could not determine most recent matching file" >&2
  exit 1
fi

# Extract sessionId from the JSONL content
SESSION_ID=$(grep -o '"sessionId":"[^"]*"' "$JSONL_FILE" | head -1 | cut -d'"' -f4)

if [ -z "$SESSION_ID" ]; then
  echo "ERROR: Could not extract sessionId from $JSONL_FILE" >&2
  exit 1
fi

if [ "$MODE" = "--report" ]; then
  # Find the history report folder containing this session ID
  REPORT_FILE=$(grep -rl "Session ID.*$SESSION_ID" "$HISTORY_DIR" 2>/dev/null | head -1)
  if [ -n "$REPORT_FILE" ]; then
    dirname "$REPORT_FILE"
  else
    echo "NO_REPORT"
  fi
else
  echo "$SESSION_ID"
fi
