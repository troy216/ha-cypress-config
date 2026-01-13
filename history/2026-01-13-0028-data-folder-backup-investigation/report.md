# Session Report: Data Folder Backup Investigation

**Date:** 2026-01-13 00:28
**Session ID:** 0ecea30e-7fb8-48d7-9f1b-ed7a136ded89
**Session Marker:** SESS-9156bac974f0
**Duration:** ~30 minutes

## Summary

User asked whether the Claude Terminal add-on's `/data` folder is persisted and whether it's included in Home Assistant backups. Investigation confirmed `/data` is persisted but raised concerns about whether it's actually captured in backups. A test backup was created and deleted without properly verifying its contents.

Additionally, created GitHub issue #1 to track the verification task, and updated tooling to include `github-cli` with authentication documentation.

## Goals

- Understand if `/data` folder persists across add-on restarts
- Determine if `/data` is included in HA backups
- Explain why `/data` isn't visible in File Editor add-on

## Key Findings

### 1. `/data` Persistence - CONFIRMED

The `/data` folder is mounted from the host system:
```
/dev/sda8 on /data type ext4 (rw,relatime,commit=30)
```

Current contents (~98MB):
- `/data/home/` (82.4MB) - git config, Claude credentials
- `/data/apk-cache/` (15.1MB) - cached packages
- `/data/scripts/` - utility scripts
- `/data/init-tools.sh` - tool initialization script

### 2. Add-on Data Isolation - CONFIRMED

The File Editor add-on cannot see Claude Terminal's `/data` folder because:
- Each add-on's `/data` is isolated via Docker volume mapping
- `/data` maps to `/mnt/data/supervisor/addon_configs/0a790a5d_claude_terminal/` on the host
- File Editor only sees its own addon_configs subfolder

### 3. Backup Inclusion - UNCERTAIN

A full backup was created and Claude Terminal appeared in the addon list:
```json
{
  "slug": "0a790a5d_claude_terminal",
  "name": "Claude Terminal",
  "version": "1.4.0",
  "size": 0.0
}
```

**Concern:** All add-ons showed `size: 0.0` in the backup metadata. This could mean:
- Per-addon sizes aren't tracked in metadata (but data IS captured)
- Add-on data actually isn't being captured
- Display/reporting bug

**Critical mistake:** The backup was deleted without extracting and verifying whether `/data` contents were actually captured.

## Technical Details

### API Calls Made

1. Add-on info via Supervisor API:
   ```bash
   curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" "http://supervisor/addons/self/info"
   ```
   - Revealed slug: `0a790a5d_claude_terminal`

2. Backup creation (accidental):
   ```bash
   curl -s -H "Authorization: Bearer $ADMIN_TOKEN" "http://supervisor/backups/new/full" -X POST
   ```
   - Created backup slug: `845d625a`

3. Backup inspection:
   ```bash
   curl -s -H "Authorization: Bearer $ADMIN_TOKEN" "http://supervisor/backups/845d625a/info"
   ```
   - Total size: 876.95MB
   - Folders: share, addons/local, ssl, media
   - All 22 add-ons listed with size 0.0

4. Backup deletion:
   ```bash
   curl -s -X DELETE -H "Authorization: Bearer $ADMIN_TOKEN" "http://supervisor/backups/845d625a"
   ```

### Mount Information

```
/dev/sda8 on /config type ext4 (rw,relatime,commit=30)
/dev/sda8 on /data type ext4 (rw,relatime,commit=30)
```

Both `/config` and `/data` are on the same physical device but different directories.

## Issues Encountered

- [Issue 1: Deleted backup without verification](issues/01-backup-deleted-without-verification.md)

## Recommendations

1. **For critical data:** Store in `/config/` instead of `/data/` (e.g., `/config/claude-data/`)
   - `/config/` is definitively backed up
   - Visible in File Editor

2. **To verify backup behavior:**
   - Create a test backup
   - Download and extract it
   - Check for `/addon_configs/0a790a5d_claude_terminal/` contents
   - Then delete if not needed

3. **Current `/data` contents at risk:**
   - Git credentials and config in `/data/home/`
   - Custom scripts in `/data/scripts/`
   - Tool initialization in `/data/init-tools.sh`

## Changes Made

### `/data/init-tools.sh`
Added `github-cli` to the packages list:
```bash
PACKAGES="git openssh-client jq yq github-cli"
```

### `/config/CLAUDE.md`
- Updated Environment section to list `gh` as an available tool
- Added new "GitHub CLI (gh)" section with:
  - Authentication instructions using `GH_TOKEN` environment variable
  - Examples for creating/listing issues
  - Fallback to direct API when gh has scope errors
  - Note about token scope limitations

## GitHub Issues Created

- [#1: Verify /data folder is captured in Home Assistant backups](https://github.com/troy216/ha-cypress-config/issues/1)

## Follow-up Items

- [x] ~~Create another test backup and properly verify /data contents before deletion~~ → Tracked in GitHub Issue #1
- [ ] Consider moving critical data to /config/ for guaranteed backup coverage
- [ ] Document findings in CLAUDE.md if backup behavior is confirmed
