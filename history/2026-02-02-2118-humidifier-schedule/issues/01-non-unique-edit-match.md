# Issue: Non-unique string match during edit

## What Happened
When appending the new automations to `automations.yaml`, the initial edit attempt used `mode: single` as the anchor string. This matched 15 times in the file since every automation ends with `mode: single`. A second attempt with slightly more context (`fan_mode: auto` + `mode: single`) still matched 2 times (both Grow AC automations end with the same climate fan_mode setting).

The third attempt used enough unique context (including `temperature: 62`) to uniquely identify the last automation in the file.

## Impact
Two failed edit attempts before success. Minor time cost (~1 minute).

## Root Cause
Claude did not include enough surrounding context in the `old_string` to uniquely identify the insertion point. The file has many automations sharing the same trailing pattern.

## Resolution
Used a longer context string including `temperature: 62` which was unique to the Grow AC Nighttime Cool automation (the last one in the file).

## Improvements
- For Claude: When appending to the end of a list-based YAML file, always include 3-4 lines of unique context from the preceding entry rather than generic trailing lines like `mode: single`.
