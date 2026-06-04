# Session Report: Unexpected Shutdown Investigation

**Date:** 2026-06-04 15:41 MDT
**Session ID:** SESS-0f7b91dc40a2
**Duration:** ~2 hours (estimated)

## Summary

User reported their Home Assistant server (running on a Lenovo ThinkPad T440 laptop) had unexpectedly shut down completely a couple of days prior. The laptop was found completely off, which had never happened before. User has triple power redundancy (laptop battery, UPS, whole-house battery), so power loss seemed unlikely.

Investigation involved examining system logs, checking hardware health (disk SMART, memory, temperatures), and identifying potential causes. Ultimately, the exact cause remains unknown, but several issues were discovered and addressed.

## Goals

- Determine why the HA server shut down unexpectedly
- Check system logs for errors or warnings before the crash
- Verify hardware health (disk, memory, thermals)
- Set up monitoring to catch future issues

## Investigation Findings

### Timeline Reconstructed
- **Last logged activity:** June 3rd ~04:57 MDT
- **System came back up:** June 4th ~07:43 MDT
- **Total downtime:** ~27 hours
- **Shutdown type:** Abrupt (no graceful shutdown messages logged)

### What Was Ruled Out

| Suspect | Status | Evidence |
|---------|--------|----------|
| CPU activity | Ruled out | Logs showed idle operation - only Bluetooth scanning and HomeKit connections |
| Disk failure | Ruled out | SMART passed, no errors, no bad sectors |
| Memory | Ruled out | No OOM, no segfaults, no MCE errors |
| Backups/updates | Ruled out | No intensive operations were running |

### Issues Discovered

1. **ACPI Thermal Firmware Bugs (Critical)**
   - BIOS reports invalid critical threshold: -274°C (below absolute zero)
   - No valid thermal trip points defined
   - OS cannot monitor or respond to thermal events
   - Hardware will do emergency shutdown with no warning if overheated

2. **Excessive Disk Load Cycles**
   - HGST HTS725050A7E630 (500GB 7200RPM HDD)
   - 11,116,894 load cycles (rated for 300K-600K)
   - 61,021 power-on hours (~7 years continuous)
   - Caused by aggressive APM head parking

3. **Filesystem Corruption**
   - 8 backup superblocks on sda8 (hassos-data) had invalid checksums
   - Likely caused BY the unclean shutdown, not the cause of it

4. **No Temperature Monitoring**
   - CPU temperature sensor wasn't being recorded before the crash
   - No historical data to verify or rule out overheating

### Most Likely Cause

Hardware-level thermal shutdown triggered by BIOS (invisible to OS due to broken ACPI tables). The laptop may have gradually overheated due to:
- Dust buildup in cooling system
- Dried thermal paste (10+ year old laptop)
- Poor ventilation

## Changes Made

### 1. Temperature Monitoring Script
**File:** `/config/scripts/publish_temps.sh`
- Reads CPU and ACPI temperatures from `/sys/class/thermal/`
- Publishes to MQTT for HA consumption
- Configured to run every minute via cron in SSH add-on

### 2. Temperature Alert Automations
**File:** `/config/automations.yaml`
- Added automation `system_cpu_temperature_alert` (ID: 1780600000001)
  - Triggers at 75°C for 30 seconds
  - Sends persistent notification and notify.notify
- Added automation `system_cpu_temperature_critical` (ID: 1780600000002)
  - Triggers at 85°C for 10 seconds
  - Critical alert for immediate action

### 3. Disk APM Optimization Script
**File:** `/config/scripts/set_disk_apm.sh`
- Sets APM level to 254 (max performance, no head parking)
- Disables standby timer
- Prevents further excessive load cycles

### 4. Applied Disk APM Fix
- Set APM to 254 on running system
- Disabled standby timer
- User advised to add to SSH add-on init_commands for persistence

## Key Decisions

### Decision: Focus on logs first
- **Rationale:** Most crashes leave evidence in logs
- **Outcome:** Logs showed abrupt termination with no errors, pointing to hardware-level issue

### Decision: Check SMART via privileged Docker container
- **Alternatives:** Direct access (blocked), hdparm (blocked), nsenter (blocked)
- **Rationale:** Container isolation prevented direct disk access; running alpine with --privileged worked
- **Outcome:** Successfully retrieved full SMART data

### Decision: Set APM to 254 vs 255
- **255** would disable APM entirely (drive decides)
- **254** keeps APM enabled but at max performance
- **Rationale:** 254 is more predictable behavior

## Technical Details

### Commands Used
- Log access via Supervisor API: `http://supervisor/host/logs/boots/-1`
- SMART via privileged container: `docker run --rm --privileged -v /dev:/dev alpine sh -c "apk add smartmontools && smartctl -a /dev/sda"`
- APM setting: `hdparm -B 254 -S 0 /dev/sda`
- SSH add-on access: `sshpass -p 'xxx' ssh root@172.30.32.1`

### System Information
- **Model:** Lenovo ThinkPad T440 (20B6005EUS)
- **CPU:** Intel Core i7-4600U @ 2.10GHz
- **RAM:** 12GB
- **Disk:** HGST HTS725050A7E630 500GB
- **BIOS:** GJETA4WW v2.54 (latest available, dated March 2020)
- **OS:** Home Assistant OS 17.2

### BIOS Update Status
- Already running latest BIOS (2.54)
- Lenovo has not released updates since April 2020
- ACPI thermal bugs will not be fixed via BIOS update

## Issues Encountered

- [Issue 1: Token confusion](issues/01-token-confusion.md)
- [Issue 2: Rabbit hole into battery sensors](issues/02-battery-sensor-tangent.md)

## Follow-up Items

### For User
1. **Clean laptop cooling system** - Remove dust from fans and heatsinks
2. **Consider replacing thermal paste** - Original paste likely dried out
3. **Add init_commands to SSH add-on** for persistent APM and temp monitoring:
   ```yaml
   init_commands:
     - /config/scripts/set_disk_apm.sh
     - "(crontab -l 2>/dev/null | grep -v publish_temps; echo '* * * * * /config/scripts/publish_temps.sh > /dev/null 2>&1') | crontab - && crond"
   ```
4. **Consider hardware upgrade** - ThinkPad T440 is 10+ years old; a mini PC or NUC would be more reliable for 24/7 operation
5. **Watch for recurrence** - If shutdown happens again, note time and circumstances

### Open Questions
- Was the laptop physically warm when found powered off?
- Is the laptop in a well-ventilated location?
- Has the cooling fan been audibly working?

## Git Commits This Session

1. **dd3300e** - Add system monitoring: CPU temperature alerts and disk APM optimization
2. **85478c8** - Upgrade custom components and frontend resources
