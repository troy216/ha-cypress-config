# Issue: Edit tool unique match difficulty

## What Happened
When appending the new automations to `automations.yaml`, the initial Edit attempt used `mode: single` as the anchor text. This matched 13 occurrences in the file. A second attempt with more context (`entity_id` + `domain` + `mode: single`) still matched 2 occurrences. A third attempt with the full block (including unique automation id) succeeded.

## Impact
Three Edit attempts before success — minor time waste, extra context tokens consumed.

## Root Cause
- Claude mistake: Started with too little context in the `old_string` parameter
- The file has many automations ending with `mode: single`, making short snippets non-unique
- Even mid-length snippets can match multiple automations with similar device actions

## Resolution
Used the full automation block including the unique `id: '1768200924978'` as anchor text.

## Improvements
- For Claude: When editing a file with many repeated patterns (like automations.yaml), always include the automation `id` or `alias` in the `old_string` to guarantee uniqueness on the first attempt
- Consider reading the last ~20 lines of the file and using a sufficiently unique block from the start
