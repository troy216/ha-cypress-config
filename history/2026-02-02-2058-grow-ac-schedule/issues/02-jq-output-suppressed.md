# Issue: jq output not displaying in terminal

## What Happened
Multiple `curl | jq` commands returned empty output despite the API returning valid JSON (confirmed by checking `wc -c` and HTTP status 200). Direct entity state checks also appeared empty. The workaround was saving curl output to a file and reading it with the Read tool.

## Impact
Several extra commands needed to verify the automations were registered. Roughly 5 extra tool calls spent debugging output visibility.

## Root Cause
- Environment limitation: The Bash tool output handling appears to suppress or truncate certain `jq` output, particularly when piped from `curl`
- The `curl -s | jq` pipeline produces output that sometimes doesn't appear in the tool results, possibly due to buffering or encoding issues in the container environment

## Resolution
Saved API responses to files (`/tmp/auto_check.json`) and used the Read tool to view the contents.

## Improvements
- For Claude: When `curl | jq` returns empty in this environment, immediately fall back to saving to a temp file and reading it, rather than trying multiple jq variations
- This is a known pattern in this container environment — prefer `curl -s URL > /tmp/file.json` followed by Read tool
