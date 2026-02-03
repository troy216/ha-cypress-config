# Session Report: CLAUDE.md & README.md Improvements

**Date:** 2026-02-03 08:45
**Session ID:** a75fc33d-6471-4b52-a297-de315c145f7f
**Marker:** SESS-7edfe7a40799
**Duration:** ~90 minutes (estimated)

## Summary

Two-part session: (1) Comprehensive review of all 15 session reports and 20 issue files to identify recurring mistakes and add preventive directives to CLAUDE.md. The review phase included critical analysis that trimmed proposals from ~40 to ~22 net new lines by preferring abstract rules over specific ones. (2) Audited README.md against actual project state, fixed 4 discrepancies: incomplete integration table, missing directories, incorrect API reference, and missing security-sensitive file in "never commit" list.

## Goals

- Read all session history reports and issue files
- Identify recurring patterns of mistakes and inefficiencies
- Propose concrete CLAUDE.md improvements
- Critically review proposals for value vs context cost (CLAUDE.md is loaded every session)
- Implement approved changes
- Audit README.md for consistency with current project state
- Fix any discrepancies found

## Changes Made

### `/config/CLAUDE.md` (sole file modified, 185 -> 207 lines)

**Change 1: YAGNI principle added to Persona (line 18)**
- Added: `- Prefer direct execution over creating artifacts; apply YAGNI ("You Aren't Gonna Need It")`
- Addresses 4+ over-engineering incidents (unnecessary scripts, excess helpers, fixing non-bugs)

**Change 2: Environment container line expanded (line 26)**
- Added API unreachability note and correct endpoint to existing container description
- Addresses 3+ incidents of attempting unreachable REST API

**Change 3: New "Problem-Solving Discipline" section (lines 62-66)**
- 4 abstract behavioral rules: simplest first, stop after 2-3 failures, question the premise, listen to user pushback
- Addresses 6+ incidents across research rabbit holes, assumption errors, and ignored user feedback

**Change 4: Automation helper guidance added to Development (line 60)**
- Added: `- When designing automations, prefer deriving state from existing entities over creating input_* helpers`
- Addresses over-engineered battery charger automation design

**Change 5: New "YAML Editing" section (lines 68-71)**
- 3 rules for Edit tool usage with list-based YAML files
- Addresses 3+ incidents of non-unique match failures in automations.yaml

**Change 6: REST API section rewritten (lines 134-152)**
- Replaced misleading `http://192.168.1.2:8123` examples with verified `http://supervisor/core/api/` proxy pattern
- Added SQLite database fallback as equal-weight alternative
- Key discovery: proxy requires `$SUPERVISOR_TOKEN` env var, NOT `.ha_token`

**Change 7: Output handling note added (lines 203-207)**
- Documents `curl | jq` empty output issue in this container
- Recommends save-to-file pattern

## Key Decisions

### Trimmed from 40 to 22 net lines
- **Rationale:** Every line in CLAUDE.md costs tokens every session. The review agent scored each proposed rule on impact (1-5), frequency, and abstraction level.
- **Dropped:** "Ask about better credentials" (special case of "simplest first"), "Read docs before answering" (one-off), "Don't delete test artifacts" (one-off), 4 of 5 automation design bullets (from single project), `apk add` non-persistence note (general Docker knowledge), separate Automation Design section (collapsed to 1 line)

### Verified Supervisor proxy before documenting
- **Rationale:** Review agent flagged that `http://supervisor/core/api/` was unverified in session history. Tested it live and discovered it works but requires `$SUPERVISOR_TOKEN` (native addon env var), not the `.ha_token` JWT. This was a critical finding that prevented documenting incorrect auth.

### Abstract rules over specific ones
- **Rationale:** User directive to prefer rules that handle whole classes of issues. "Simplest first" covers "ask about better credentials," "try direct execution," and "don't over-engineer" as sub-cases.

## Technical Details

### Supervisor Proxy Verification
```bash
# .ha_token (JWT) -> 401 Unauthorized
curl -s -o /tmp/test.json -w "%{http_code}" -H "Authorization: Bearer $(cat /config/.ha_token)" http://supervisor/core/api/states
# Result: 401

# $SUPERVISOR_TOKEN (native addon token) -> 200 OK
curl -s -o /tmp/test.json -w "%{http_code}" -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/api/states
# Result: 200, valid JSON with entity states
```

### Token Types
- `.ha_token`: JWT format (`eyJhbG...`), long-lived access token for HA REST API
- `$SUPERVISOR_TOKEN`: Hex format (`984c05...`), addon's native Supervisor token, works with `http://supervisor/` endpoints
- `.ha_supervisor_admin_token`: Admin-level Supervisor token extracted from HA Core container, used for privileged Supervisor API calls

## Issues Encountered

- [Issue 1: Supervisor proxy token discovery](issues/01-supervisor-proxy-token.md)

## Post-Implementation Verification (CLAUDE.md)

User confirmed that both token sources (`$SUPERVISOR_TOKEN` env var and `/config/.ha_supervisor_admin_token` file) are documented clearly enough for new sessions to know which to use and when. The API Access section distinguishes them by use case:
- `$SUPERVISOR_TOKEN` for HA state/service access via Supervisor proxy
- Admin token file for privileged Supervisor operations (logs, addon management)

---

## Part 2: README.md Audit and Update

### `/config/README.md` (137 -> 157 lines)

**Change 1: Integration table completed**
- Was listing 6 of 13 integrations. Added 7 missing: ble_adv (v1.8.3), cielo_home (v1.8.9), climate_template (v0.8.0), hass_agent (2022.11.9), mcp_server_http_transport (v1.0.0), oidc_provider (v1.0.0), webrtc (v3.6.1)
- All 6 previously listed versions verified still accurate

**Change 2: Directory structure updated**
- Added `scripts/` (utility scripts like find-session.sh) and `history/` (session reports and issue analysis)
- Runtime/third-party dirs (www, node-red, tts, deps, tmp, glances, image) intentionally omitted

**Change 3: API Reference rewritten**
- Removed non-existent `/api/error_log` endpoint
- Changed all endpoints from direct REST API paths to Supervisor proxy paths (`http://supervisor/core/api/...`)
- Added note that REST API at `192.168.1.2:8123` is unreachable from container
- Added Supervisor Admin API log endpoints table

**Change 4: "Files to Never Commit" updated**
- Added `.ha_supervisor_admin_token` — security-sensitive file already in `.gitignore` but missing from README

## Follow-up Items

- Monitor whether the YAGNI principle and Problem-Solving Discipline rules actually reduce over-engineering and rabbit holes in future sessions
- Consider whether the `.ha_token` line in Environment section should note it's only for HA REST API (which is unreachable) vs `$SUPERVISOR_TOKEN` for proxy access
- The `**Host:**` line in Environment still shows `http://192.168.1.2:8123` — could be confusing since it's unreachable, but it documents the actual HA instance address for reference
- Integration versions in README will drift over time as HACS updates components — consider a periodic review
