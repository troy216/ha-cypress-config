# Session Report: Battery Charge Automation Redesign

**Date:** 2026-04-07 09:41
**Session ID:** 0f200d6c-bb81-4359-9136-f7561ae6fe0e
**Duration:** ~45 minutes (estimated, includes prior session that was restarted)

## Summary

Redesigned the battery charging automation system for FLA marine batteries (2x4x12V with 13.3V charger on `switch.zp_garage_outlet`). The old system had 3 separate automations and a count-based flatness sensor that was stopping charges prematurely (25-30 minutes instead of expected 4-24 hours). Replaced with a unified automation with multiple triggers and a time-based rolling window sensor.

## Goals

- Simplify from 3 automations to 1 unified automation + 1 watchdog
- Replace count-based sensor (20 readings, ~10 min window) with time-based sensor (30-min rolling windows)
- Add multiple trigger paths: schedule (Tue/Fri 8AM), manual switch-on, HA restart recovery
- Remove the complicated HA Restart Recovery automation
- Fix premature charge completion by using larger comparison windows
- No minimum charge time — rely on growing window + flatness ratio instead

## Changes Made

### 1. `/config/includes/template.yaml` — Sensor Rewrite (lines 29-147)
Replaced `sensor.battery_charge_complete` implementation:

**Old**: Count-based, stored last 20 bare values, split into older[:10] and recent[-10:] halves (~5-min windows at 30s intervals)

**New**: Time-based rolling windows with growing window logic:
- Stores `[timestamp, value]` pairs, keeps 90 min of history
- Window size: `min(elapsed_time / 2, 30 minutes)` — grows from 0 to 30 min
- Compares `avg(t-60min, t-30min)` vs `avg(t-30min, t)` at full size
- Requires 2+ readings per window before reporting non-zero ratio
- Clears all state when switch turns off (clean slate for next cycle)
- Tracks `charge_start_ts` attribute (resets on switch-on, clears on switch-off)
- Exposes diagnostics: `window_size_minutes`, `recent_avg`, `samples`

Same `unique_id: battery_charge_complete` preserved for entity continuity.

### 2. `/config/automations.yaml` — Unified Automation (lines 1-109)
Replaced 3 automations with 1 unified `Battery: Charge Cycle` (id: `1770100000010`):

**Triggers:**
- `scheduled`: Time trigger at 08:00, conditioned on Tue/Fri + switch off
- `manual`: State trigger when `switch.zp_garage_outlet` turns on
- `ha_restart`: Homeassistant start event, conditioned on switch already on

**Logic:**
- Only turns switch on for `scheduled` trigger (others already on)
- 5-minute monitoring loop checks flatness ratio > 0.98 AND recent_avg > 0.5A
- Detects manual switch-off and stops gracefully with notification
- 48-hour safety cutoff
- Notifications at start, completion, interruption, and safety cutoff
- `mode: single` prevents overlapping runs

**Removed:**
- `Battery: Scheduled Charge Cycle` (id: 1770100000001) — blueprint-based, replaced
- `Battery: HA Restart Recovery` (id: 1770100000003) — functionality merged into unified automation

**Kept unchanged:**
- `Battery: Charge Safety Watchdog` (id: 1770100000002) — independent 50-hour safety net (minor YAML cleanup)

### 3. `/config/blueprints/automation/homeassistant/custom/battery_charge_cycle.yaml` — Deleted
No longer needed; automation is now direct YAML, not blueprint-based.

## Key Decisions

### 1. Time-based windows instead of count-based
- **Decision:** Use 30-minute time windows with timestamp-filtered samples
- **Alternatives:** Larger count-based buffer (e.g., 100 readings), HA statistics integration, AppDaemon
- **Rationale:** Count-based windows have unpredictable time span depending on sensor update frequency. Time-based is deterministic and self-documenting. Native Jinja2 avoids external dependencies.

### 2. Growing window: `min(elapsed/2, 30min)`
- **Decision:** Window starts at 0 and grows to 30 minutes
- **Alternatives:** Fixed 30-min window with min_charge_minutes guard, fixed small window
- **Rationale:** User insisted no minimum charge time — growing window naturally prevents false-flat early in the cycle (high current delta between windows). Elegant: early comparisons have small windows but large current differences; late comparisons have large windows but small current differences.

### 3. Direct automation instead of blueprint
- **Decision:** Write automation directly in `automations.yaml`
- **Alternatives:** Update the blueprint to support multiple triggers
- **Rationale:** Multi-trigger logic with per-trigger conditions is awkward in blueprint inputs. Single instance, no reuse benefit. Simpler to maintain.

### 4. No minimum charge time
- **Decision:** Start flatness checking as soon as 2 readings exist in each window
- **Alternatives:** 15-minute or 60-minute minimum
- **Rationale:** User's insight — early windows will naturally show large current differences (high initial draw vs declining), so false-flat detection won't happen. The growing window is self-protecting.

### 5. Keep same entity name/unique_id
- **Decision:** Reuse `battery_charge_complete` unique_id
- **Rationale:** Preserves dashboard references, automation references, and entity history continuity.

### 6. Use 0 as sentinel for charge_start_ts instead of None
- **Decision:** Return `{{ 0 }}` when not charging, not `{{ none }}`
- **Rationale:** `{{ none }}` in Jinja2 outputs the string "None" which could cause type confusion when reading back. `0` is a clean numeric sentinel — any real timestamp is > 0.

## Technical Details

### Sensor Data Flow
```
sensor.zp_garage_current (raw current, ~30s updates)
  → triggers sensor.battery_charge_complete
    → stores [timestamp, value] pairs in samples attribute
    → computes rolling window averages
    → outputs ratio (0 to 1.0)
```

### Automation Trigger Matrix
| Trigger | Condition | Switch Action |
|---------|-----------|---------------|
| scheduled (8AM) | Tue/Fri + switch off | Turn ON |
| manual (switch→on) | Always passes | None (already on) |
| ha_restart | Switch already on | None (already on) |

### Key Parameters
- `flatness_ratio`: 0.98 (to be tuned after real-world testing)
- `max_charge_hours`: 48
- `min_current_floor`: 0.5A
- `window_max`: 30 minutes (hardcoded in sensor)
- `sample_retention`: 90 minutes (hardcoded in sensor)
- `check_interval`: 5 minutes (in automation repeat loop)

## Issues Encountered

- [Issue 1: Session restart due to rate limit/context](issues/01-session-restart.md)

## Follow-up Items

- **Test the new sensor**: Turn on the switch manually and watch `sensor.battery_charge_complete` attributes populate. Verify `charge_start_ts`, `window_size_minutes`, and `samples` behave correctly.
- **Monitor first real charge cycle**: Check that ratio stays low during active charging and converges to 1.0 only when current truly stabilizes.
- **Tune flatness_ratio**: User originally wanted 0.99 or 1.0. Start with 0.98 and adjust based on real charge data with the new 30-min windows.
- **Clean up orphaned entity**: After HA restart, check if the old `sensor.battery_charge_complete` entity needs to be removed from the entity registry (Settings > Entities). Since we reused the same unique_id, it should update in place.
- **Verify `mode: single` behavior**: Confirm that when the automation turns the switch on (scheduled), the resulting switch→on state change doesn't cause issues (should be dropped by mode:single).
