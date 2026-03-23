# Session Report: Git History Cleanup & Auto-Backup Removal

**Date:** 2026-03-23 09:30
**Session ID:** 949c6f06-d4bd-4b37-81e4-229b0a5d27ec
**Duration:** ~60 minutes (estimated, includes prior session work)

## Summary

Comprehensive cleanup of git history and removal of the broken auto-backup system. The session spanned two conversations — the first added `.cache/` to `.gitignore` and removed the auto-backup automation; the second analyzed all 16 auto-backup commits, rewrote their messages with semantic descriptions, and removed dead config.

## Goals

- Understand and document what each auto-backup commit actually contained
- Remove the auto-backup system (automation + script) since Claude handles commits at startup
- Prefix all auto-backup commit messages with `AUTO-COMMIT:` and add descriptive content
- Remove dead configuration: unused `timed_enforcer` blueprint and redundant tower pump automations

## Changes Made

### 1. `.gitignore` — Added `.cache/` (prior session, commit `04e0400`)
- Brand icon cache files were being tracked unnecessarily
- Removed `.cache/` from git tracking while keeping files locally

### 2. Removed auto-backup system (prior session, commit `8b1064e`)
- **Deleted:** `/config/shell/git-push-config.sh` and `/config/shell/` directory
- **Emptied:** `/config/automations/maintenance.yaml` (contained only the backup automation)
- **Removed:** `shell_command.git_push_config` from `/config/configuration.yaml`
- **Reason:** Push was silently failing (timeout/auth issues), generic commit messages provided no context, and Claude now detects uncommitted changes at startup with descriptive commits

### 3. Removed dead config (commit `1f03a61`)
- **Deleted:** `/config/blueprints/automation/homeassistant/timed_enforcer.yaml`
  - Blueprint was never instantiated by any automation — confirmed via search of all YAML files
- **Removed from:** `/config/automations/grow_room.yaml` (lines 1-29)
  - Tower pump ON/OFF cycle automations (IDs: `1766608888636`, `1766609124183`)
  - Pump scheduling is now handled by Tasmota device firmware directly

### 4. Rewrote 16 auto-backup commit messages (force push `63f8cc6...1f03a61`)
- Used `git filter-branch --msg-filter` with a hash-to-message mapping script
- All commits prefixed with `AUTO-COMMIT:` to flag as non-intentional
- Each message describes actual changes (HACS upgrades, new automations, integration installs, etc.)

#### Rewritten messages:
| Date | New Message |
|------|-------------|
| 2025-10-13 | AUTO-COMMIT: Add daily git auto-backup automation, shell_command, and git-push-config.sh script |
| 2025-10-29 | AUTO-COMMIT: Update ble_adv integration — add RW codec, refactor mantra codec, update config flow and light entity |
| 2025-11-29 | AUTO-COMMIT: Add timed_enforcer blueprint — scheduled ON window with periodic state correction for grow lights/pumps |
| 2025-12-20 | AUTO-COMMIT: Install Bambu Lab integration (v2.0.x) with full printer control, AMS support, HMS errors, and timelapse/print cache |
| 2025-12-21 | AUTO-COMMIT: Update Bambu Lab print cache (Bucket Net Port 2) and timelapse recording |
| 2025-12-25 | AUTO-COMMIT: Add grow tower pump automations — 15-min ON/OFF cycle for hydroponic tower pump |
| 2025-12-26 | AUTO-COMMIT: Update HACS integrations — ble_adv (add smartelfin codec), cielo_home (add number/switch entities, refactor API), eufy_security, power-flow-card-plus |
| 2026-01-05 | AUTO-COMMIT: Add grow light automations — turn grow LEDs on/off in response to tower white 6000K switch, with 30-min cooldown |
| 2026-01-12 | AUTO-COMMIT: Initial Claude Terminal setup — add CLAUDE.md, install MCP Server v1.0.0 and OIDC Provider v1.0.0, update Node-RED, update Bambu Lab |
| 2026-02-04 | AUTO-COMMIT: Add Chrome DevTools domains to Claude Code allowed WebFetch permissions |
| 2026-02-06 | AUTO-COMMIT: Update Bambu Lab — refactor AMS filament load/unload into separate methods, add AMS model constants |
| 2026-02-27 | AUTO-COMMIT: Update MCP Server to v1.0.2 and OIDC Provider to v1.1.1 (add persistent refresh token storage) |
| 2026-03-19 | AUTO-COMMIT: Update MCP Server to v1.3.2 — add MCP tools, prompts, resources, completions, dashboard/config managers |
| 2026-03-21 | AUTO-COMMIT: Update OIDC Provider to v1.2.0 (repo renamed to hass-oidc-server) |
| 2026-03-22 | AUTO-COMMIT: Add cached brand icons — frontend, mqtt, tasmota, zha (dark mode) |
| 2026-03-23 | AUTO-COMMIT: Add cached brand icons — enphase_envoy, esphome, hassio, nmap_tracker (dark mode) |

## Key Decisions

### 1. Remove auto-backup rather than fix it
- **Alternatives:** Fix push auth, add retry logic, switch to SSH
- **Decision:** Remove entirely — Claude detects changes at startup and commits with descriptive messages
- **Rationale:** The auto-backup had multiple problems (silent push failures, `git add -A` catching everything, generic messages). Claude's startup check is more reliable and informative.

### 2. Prefix with `AUTO-COMMIT:` rather than rewrite as normal commits
- **Decision:** User wanted to clearly distinguish auto-committed changes from intentional work
- **Rationale:** Makes git history scannable — you can immediately see which commits were human-coordinated vs automated

### 3. Force push to rewrite history
- **Risk:** Rewrites all hashes from Oct 2025 onward
- **Rationale:** Personal single-contributor repo, no downstream consumers

### 4. Remove timed_enforcer blueprint
- **Decision:** Delete — never used by any automation
- **Rationale:** Dead code. Can be recreated from git history if ever needed.

### 5. Remove tower pump automations
- **Decision:** Delete — pump scheduling moved to Tasmota firmware
- **Rationale:** User confirmed Tasmota handles this directly, HA automations are redundant. Device was also flagged unavailable in Jan 2026 log scan.

## Technical Details

- `git filter-branch --msg-filter` with a shell script mapping 16 commit hashes to new messages
- Filter rewrote 67 total commits (16 targeted + 51 descendants whose hashes changed)
- Backup refs cleaned up with `git update-ref -d refs/original/refs/heads/main`

## Issues Encountered

- [Issue 1: Timeouts in prior session](issues/01-session-timeouts.md)

## Follow-up Items

- **Bambu Lab binary bloat:** Commit `428cf97` (Dec 20) added ~3.1M lines including gcode files, timelapse videos, and print cache. These binary blobs are permanently in git history. Consider adding Bambu print paths to `.gitignore` and potentially using `git filter-repo` to remove large binaries if repo size becomes a concern.
- **switch.grow_tower_pump unavailable:** Entity was flagged unavailable Jan 12. Now that automations are removed, the entity itself could potentially be cleaned up if the device is no longer connected.
- **Grow light automations still active:** The tower grow light on/off automations remain enabled and functional. All referenced entities exist.
