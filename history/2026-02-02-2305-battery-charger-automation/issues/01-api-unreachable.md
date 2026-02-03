# Issue: HA REST API Unreachable from Container

## What Happened
The initial attempt to fetch sensor history data used the HA REST API (`http://192.168.1.2:8123/api/history/period/...`). All API calls timed out without returning any response, despite the API token being valid.

## Impact
~10 minutes spent on API attempts before switching to direct database access. Minor delay but recovered quickly.

## Root Cause
Network isolation between the Claude Code addon container and the HA Core container. The addon can reach `http://supervisor/` endpoints but not `http://192.168.1.2:8123` directly. This is a known container networking limitation.

## Resolution
Installed `sqlite3` via `apk add` and queried `/config/home-assistant_v2.db` directly. This worked well and provided full access to historical state data. Used `states_meta` table to find entity metadata IDs, then queried `states` table with timestamp filters.

## Improvements
- **For Claude:** When API calls time out, immediately fall back to direct database queries. The HA SQLite database is always accessible at `/config/home-assistant_v2.db`.
- **For System:** Consider pre-installing `sqlite3` in the addon container via `/data/init-tools.sh`.
- **Alternative:** Try the Supervisor proxy (`http://supervisor/core/api/...`) which may work from within the addon network.
