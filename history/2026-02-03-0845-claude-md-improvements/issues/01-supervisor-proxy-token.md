# Issue: Supervisor Proxy Requires $SUPERVISOR_TOKEN, Not .ha_token

## What Happened

The plan proposed documenting the Supervisor proxy (`http://supervisor/core/api/`) using `TOKEN=$(cat /config/.ha_token)` — the same token pattern from the old REST API docs. During pre-implementation verification, this returned 401 Unauthorized. The correct token is `$SUPERVISOR_TOKEN` (the addon's native environment variable).

## Impact

Low — caught during verification before committing incorrect docs. Without verification, this would have replaced one set of broken documentation with another, potentially causing the same confusion in future sessions.

## Root Cause

The original plan was designed by an agent that didn't have access to test the endpoint. The plan assumed the `.ha_token` (a JWT long-lived access token) would work with the Supervisor proxy, but the Supervisor proxy requires the addon's native Supervisor token (a hex-format token provided as an environment variable).

## Resolution

Updated all Supervisor proxy examples to use `$SUPERVISOR_TOKEN` instead of `$(cat /config/.ha_token)`. Added a comment in the code example clarifying: "uses $SUPERVISOR_TOKEN env var, NOT .ha_token".

## Improvements

- **For Claude:** Always verify API patterns before documenting them. The review agent correctly flagged this as needing verification — that check prevented a repeat of the exact problem we were trying to fix.
- **For System:** The three token types (`.ha_token`, `$SUPERVISOR_TOKEN`, `.ha_supervisor_admin_token`) serve different purposes and should be clearly distinguished in documentation.
