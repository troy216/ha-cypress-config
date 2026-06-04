# Issue: Token Confusion

## What Happened

Early in the session, I attempted to access the Supervisor API logs using the admin token stored at `/config/.ha_supervisor_admin_token`. This token returned 403 Forbidden errors. I then asked the user to provide a new token, and they provided a long-lived access token from the HA UI.

This token also returned 403 on Supervisor API endpoints. I eventually discovered that the built-in `$SUPERVISOR_TOKEN` environment variable (automatically provided to add-ons) actually had the necessary permissions all along.

## Impact

- ~10 minutes spent troubleshooting token access
- User had to generate a new token unnecessarily
- Confusion about which token does what

## Root Cause

Multiple factors:
1. **Claude assumption:** I assumed the admin token file was still valid after a restart, but it had likely been invalidated
2. **Misunderstanding:** The user-provided token was a HA long-lived access token, not a Supervisor admin token - these serve different purposes
3. **Overlooked solution:** The `$SUPERVISOR_TOKEN` env var was available and working the whole time for the endpoints I needed

## Resolution

Used `$SUPERVISOR_TOKEN` which successfully accessed:
- `/supervisor/host/logs`
- `/supervisor/host/logs/boots/-1`
- `/supervisor/host/info`
- Other Supervisor API endpoints

## Improvements

### For Claude
- Check `$SUPERVISOR_TOKEN` first before asking for tokens
- Understand the difference between:
  - `$SUPERVISOR_TOKEN` - add-on's automatic token, good for most Supervisor API calls
  - Long-lived access tokens - for HA Core API, not Supervisor admin endpoints
  - Supervisor admin token - extracted from HA Core container, for privileged operations

### For Documentation
- CLAUDE.md could clarify which token to use for which endpoint
- Current docs mention using `.ha_supervisor_admin_token` but don't note it expires on restart
