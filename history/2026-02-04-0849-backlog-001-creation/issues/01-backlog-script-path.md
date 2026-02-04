# Issue: Backlog script path mismatch

## What Happened

First attempt to run `./.backlog-plugin/backlog-new` failed with "No such file or directory". The CLAUDE.md references `.backlog-plugin/backlog-new` but the actual script is at `/config/agentic-backlog/backlog-new` (the submodule path).

## Impact

Minor — one extra command to locate the script via Glob. ~30 seconds lost.

## Root Cause

The `backlog-prompt.md` workflow documentation references `.backlog-plugin/` paths, but the submodule was added as `agentic-backlog/`. The CLAUDE.md was likely written before or independently of the actual submodule setup.

## Resolution

Used the correct path `/config/agentic-backlog/backlog-new` after locating it with Glob.

## Improvements

- **For System:** Update CLAUDE.md or backlog-prompt.md to reference the correct path (`agentic-backlog/` instead of `.backlog-plugin/`), or create a symlink `.backlog-plugin -> agentic-backlog` for compatibility.
