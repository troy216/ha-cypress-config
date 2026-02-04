# Session Report: Battery Charger Minute-Scale Flatness Detection

**Date:** 2026-02-04 10:04
**Session ID:** ad2d3e66-2cf0-4370-99a1-16b79aed34e2
**Duration:** ~60 minutes (estimated)

## Summary

Redesigned the battery charger automation's flatness detection from hour-scale (1h/4h rolling mean convergence) to minute-scale (~5-minute consecutive window ratio). Replaced two statistics sensors with a single trigger-based template sensor that stores recent readings in an attribute and computes a unitless ratio of two consecutive 5-minute windows.

## Goals

- **Primary:** Enable fast flatness detection — if the current curve goes flat in 10 minutes, stop in 10 minutes (not hours)
- **Secondary:** Reduce the number of helper entities — ideally one sensor instead of two
- **Tertiary:** Keep a unitless, self-scaling threshold (ratio approaching 1.0) rather than a unit-coupled derivative threshold (A/min)

## Changes Made

### 1. `/config/includes/template.yaml`
- **Added** trigger-based template sensor `sensor.battery_charge_complete`
- Triggers on every `sensor.zp_garage_current` state change (~30s)
- Stores last 20 readings in `samples` attribute (~10 min of data)
- Splits into two halves (older 10 / recent 10) = two consecutive ~5-min windows
- Outputs `min(recent_avg, older_avg) / max(recent_avg, older_avg)` — approaches 1.0 when flat
- Exposes `current_avg` attribute (recent 5-min average) for floor checks and notifications
- Outputs 0 until 20 readings accumulate (~10 min warmup)

### 2. `/config/includes/sensors.yaml`
- **Removed** both statistics sensors:
  - `sensor.battery_charger_current_1h_mean` (1-hour rolling mean)
  - `sensor.battery_charger_current_4h_mean` (4-hour rolling mean)
- File now contains an empty list `[]` (still included via `sensor: !include` in configuration.yaml)

### 3. `/config/blueprints/automation/homeassistant/custom/battery_charge_cycle.yaml`
- **Removed inputs:** `current_short_avg`, `current_long_avg`, `min_charge_hours`
- **Added inputs:** `flatness_sensor` (the template sensor entity), `min_charge_minutes` (default 15)
- **Kept:** `flatness_ratio` (same unitless threshold, default 0.95), `min_current_floor`, all schedule/notification inputs
- **Changed loop delay:** 1 hour → 5 minutes
- **Changed flatness check:** Now reads ratio from `flatness_sensor` state and `current_avg` from its attribute
- Updated header comments and notification messages to reflect new approach

### 4. `/config/automations/battery.yaml`
- **Charge Cycle (id: 1770100000001):**
  - Updated inputs to match new blueprint schema
  - `flatness_sensor: sensor.battery_charge_complete`
  - `min_charge_minutes: 15`, `flatness_ratio: 0.98`
  - Updated description
- **Watchdog (id: 1770100000002):**
  - Fixed description to match actual 50-hour trigger (was incorrectly saying 26 hours)
  - No structural changes
- **Restart Recovery (id: 1770100000003):**
  - Reduced wait from 4.5 hours to 15 minutes
  - Changed loop from 1-hour to 5-minute intervals
  - Uses `sensor.battery_charge_complete` for flatness check with `current_avg` attribute for floor check
  - Updated notification messages

## Key Decisions

### 1. Ratio vs. Derivative Approach
- **Initial plan:** Use HA's `derivative` integration (single sensor, A/min output)
- **User pushed back:** A/min threshold is unit-coupled, ratio is more universal
- **Final decision:** Keep the ratio concept (unitless, self-scaling), just shrink windows from hours to minutes
- **Rationale:** Ratio of 0.98 means "within 2%" regardless of absolute current level — no recalibration needed if steady-state current changes

### 2. Single Sensor vs. Two Statistics Sensors + Template
- **User wanted:** One helper entity, not two or three
- **Solution:** Trigger-based template sensor that stores its own sliding window in an attribute
- **Trade-off:** More complex template logic, but only one entity to manage
- **Alternative considered:** Two short-window statistics sensors (5min, 10min) with ratio in blueprint template — simpler internally but requires two helper entities

### 3. Consecutive Windows vs. Overlapping
- **User's specific proposal:** `avg(-5 to 0) / avg(-10 to -5)` — two non-overlapping consecutive 5-min windows
- **Implementation:** Store 20 readings, split into first 10 (older) and last 10 (recent)
- **Why not overlapping:** Overlapping windows (like 5min_mean / 10min_mean) dilute the signal because the 10-min window includes the 5-min data

### 4. Sensor Naming
- **Options considered:** `battery_charger_flatness_ratio`, `battery_current_stability`, `battery_charge_flatness`
- **Chosen:** `battery_charge_complete` — value approaching 1.0 maps intuitively to "charging is complete"
- **Caveat:** Not technically SOC, but pragmatically useful

### 5. Continuous Operation
- **Decision:** Let the sensor run continuously (even when charger is off)
- **Rationale:** Computation is trivial (~30s interval, list of 20 floats). Adding an on/off condition risks stale ratio values causing false flat detection at cycle start.

## Technical Details

### Template Sensor Architecture
```
sensor.zp_garage_current (raw, ~30s updates)
    ↓ (trigger: state change)
sensor.battery_charge_complete (trigger-based template)
    ├── state: ratio of older_half / recent_half (0-1)
    ├── attr.samples: list of last 20 readings
    └── attr.current_avg: mean of last 10 readings
```

### Flatness Detection Logic
```
is_flat = (ratio > 0.98) AND (current_avg > 0.5A)
stop = (minutes >= 15 AND is_flat) OR (hours >= 48)
```

### Window Math
- 20 readings × 30s = ~10 minutes total
- Split into two halves of 10 readings each = ~5 minutes per window
- Ratio = min(recent, older) / max(recent, older)
- Warmup: outputs 0 until 20 readings accumulated

## Issues Encountered

### [Issue 1: Initial Derivative Plan Needed Course Correction](issues/01-derivative-vs-ratio.md)
The initial plan used HA's derivative integration with an A/min threshold. The user correctly identified that a unitless ratio is better. This required replanning mid-session.

## Follow-up Items

- **HA restart required** to create the new template sensor entity and remove old statistics entities
- **Monitor first charge cycle** — verify the sensor populates correctly and the ratio behaves as expected
- **Tune flatness_ratio** if 0.98 triggers too early or too late with the new 5-minute windows
- **Consider tightening watchdog** from 50 hours — with minute-scale detection, 50h is very generous
- **Old statistics sensor entities** may persist in HA's entity registry after removing from YAML — clean up via Settings > Entities if needed
- **Future: ESP32 voltage sensor** for direct SOC monitoring (noted in previous session)

## Git History

| Commit | Description |
|--------|-------------|
| `6af5064` | Redesign battery charger to minute-scale flatness detection |
