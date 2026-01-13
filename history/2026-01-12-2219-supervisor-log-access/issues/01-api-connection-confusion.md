# Issue: Initial API Connection Confusion

## What Happened

Early in the session, API calls to the Supervisor were returning empty responses or parse errors. Multiple attempts to access `/api/hassio/*` endpoints via the HA REST API proxy returned 401, and direct Supervisor API calls had inconsistent results.

This caused confusion about:
1. Whether the SUPERVISOR_TOKEN was valid
2. Whether the hassio API proxy was enabled
3. Which endpoints were actually accessible

## Impact

- ~15 minutes spent troubleshooting connectivity
- Multiple redundant API calls to diagnose the issue
- Confusion between two authentication methods (HA token vs SUPERVISOR_TOKEN)

## Root Cause

Multiple factors contributed:

1. **Two different APIs with different auth:**
   - HA REST API (`/api/*`) uses long-lived access token
   - Supervisor API (`http://supervisor/*`) uses SUPERVISOR_TOKEN
   - `/api/hassio/*` is a proxy that has its own auth requirements

2. **jq parse errors on 401 responses:**
   - When API returned "401: Unauthorized", jq tried to parse it as JSON
   - This made errors look like connection/parsing issues

3. **Output suppression:**
   - Some bash command output wasn't displaying properly
   - Had to save to files and read them separately

## Resolution

- Identified that SUPERVISOR_TOKEN works for some endpoints
- Discovered role-based access control limits which endpoints are available
- Confirmed HA long-lived token works for HA REST API, not for hassio proxy

## Improvements

### For Claude
- When API calls return empty, immediately check HTTP status code with `-w "%{http_code}"`
- Save API responses to files first, then parse with jq
- Clearly distinguish between HA REST API and Supervisor API from the start

### For User
- Could document which tokens work for which APIs in CLAUDE.md

### For System
- Add helper functions in init-tools.sh for common API calls
- Example: `supervisor_api()` that handles auth and error checking
