# Issue: Stale Supervisor Admin Token

## What Happened
The admin token stored at `/config/.ha_supervisor_admin_token` returned 403 Forbidden for all Supervisor API endpoints. This blocked the initial diagnostics (logs, addon info, host info).

## Impact
~2 minutes wasted on failed API calls before identifying the issue. Required a second round of API calls.

## Root Cause
The token was extracted from the HA Core container at some point in the past. After HA restarts, the container gets a new `SUPERVISOR_TOKEN`, invalidating the old one.

## Resolution
Discovered that the `$SUPERVISOR_TOKEN` environment variable (injected into this addon's container by the Supervisor) already has sufficient permissions for all needed endpoints. Wrote it to the token file.

## Improvements
- **For Claude:** Check `$SUPERVISOR_TOKEN` first before trying the file-based token. The env var is always current.
- **For System:** Consider updating CLAUDE.md to note that `$SUPERVISOR_TOKEN` is preferred over the file-based admin token, and the file is just a fallback/cache.
