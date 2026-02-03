# Session Report: Battery Charger Automation

**Date:** 2026-02-02 23:05
**Session ID:** 00d4f704-7e91-4f71-a532-9e7e33ae86b1
**Duration:** ~90 minutes (estimated)

## Summary

Designed and implemented an automated FLA (flooded lead-acid) battery charging system using a ZigBee power monitoring outlet in Home Assistant. The system periodically charges 2x4x12V marine batteries with a "dumb" 13.3V constant-voltage charger, using slope-based detection to determine when batteries are fully charged.

The solution involved analyzing real charging data from the HA database, researching FLA battery best practices, designing a slope detection algorithm using statistics sensor convergence, conducting a thorough edge case review, and implementing the complete automation system.

## Goals

- Automate periodic charging of FLA battery bank via `switch.zp_garage_outlet`
- Determine optimal charge frequency given voltage balancer drain
- Implement intelligent charge-stop logic (slope-based, not threshold-based)
- Recommend whether to use current or power sensor for monitoring
- Research FLA battery health considerations at 13.3V

## Changes Made

### `/config/configuration.yaml`
Added two `statistics` platform sensors for slope detection:
- `sensor.battery_charger_current_1h_mean` — 1-hour rolling mean of AC current
- `sensor.battery_charger_current_4h_mean` — 4-hour rolling mean of AC current

These are the foundation of the slope detection: when the short and long averages converge, the charging curve has flattened.

### `/config/blueprints/automation/homeassistant/custom/battery_charge_cycle.yaml`
**New file.** Blueprint for the charge cycle automation with configurable inputs:
- Charger switch entity, statistics sensor entities
- Schedule days (default Mon+Thu), start time
- Min/max charge hours, flatness threshold, minimum current floor
- Notification service

Core logic: turn on charger, loop hourly checking if `abs(1h_mean - 4h_mean) < threshold`, stop when flat (after minimum time) or at safety maximum.

Includes extensive documentation comments explaining the algorithm, why slope detection is used instead of thresholds, and safety considerations.

### `/config/automations.yaml`
Added three automations:
1. **Battery: Scheduled Charge Cycle** — Blueprint instance configured for Mon/Thu at 6 AM
2. **Battery: Charge Safety Watchdog** — Turns off outlet after 26 hours continuous on-time (catches HA restart mid-cycle)
3. **Battery: HA Restart Recovery** — On HA start, if outlet is on, waits for statistics to populate then monitors for flatness

## Key Decisions

### 1. Slope Detection via Statistics Sensor Convergence
- **Decided:** Compare 1h and 4h rolling mean sensors; when they converge within 0.03A, curve is flat
- **Alternatives:** `trend` binary sensor (gradient too small vs noise), `derivative` sensor (too noisy on raw data), template storing previous values in helpers (user wanted to avoid helpers)
- **Rationale:** Two statistics sensors naturally smooth noise (±15% down to ~±1%) and their convergence directly measures what we care about — whether the current is still changing

### 2. Current Sensor Over Power Sensor
- **Decided:** Use `sensor.zp_garage_current`
- **Data:** Steady-state noise: current ±15% vs power ±53%
- **Rationale:** Current is dramatically cleaner, making slope detection more reliable

### 3. Charge Every 3-4 Days (Mon + Thu)
- **Decided:** Day-of-week schedule instead of `tm_yday % 3`
- **Data:** Batteries drained from charged to 12.4V (~60% SOC) in 5 days due to voltage balancer load
- **Rationale:** Mon+Thu gives alternating 3/4-day intervals, keeps batteries above 80% SOC, avoids year-boundary gaps that `tm_yday % 3` would create

### 4. Blueprint Over Direct Automation
- **Decided:** Blueprint with configurable inputs
- **Alternatives:** Direct automation with hardcoded values, helper entities for configuration
- **Rationale:** User wanted configurability without disconnected helper entities. Blueprint inputs live in the automation config, visible in the UI.

### 5. No Helper Entities
- **Decided:** Track charge state via outlet switch state, detect flatness via statistics sensors, store config in blueprint inputs
- **Rationale:** User explicitly preferred avoiding disconnected helpers. All state is derivable from existing entities.

### 6. Enhanced Flat Condition (from edge case review)
- **Decided:** Flat condition requires: sensors available AND `abs(diff) < threshold` AND `current > 0.5A`
- **Rationale:** The 0.5A floor catches charger failure/tripped breaker (current at 0 would otherwise look "flat"). Availability checks prevent false flat after HA restart when sensors report "unknown".

## Technical Details

### Data Analysis
Queried the HA SQLite database directly (`/config/home-assistant_v2.db`) after the REST API was unreachable from the container. Analyzed two complete charge cycles:
- **Cycle 1 (Jan 23-25):** Started at ~2.3A, 48h duration (manually stopped)
- **Cycle 2 (Jan 30 - Feb 2):** Started at 9.0A (from 12.4V), charging curve analyzed in detail

Key findings from hourly averages:
- Exponential current decay: 9.0A → 0.89A (8h) → 0.84A (12h) → 0.76A (steady state)
- Hourly delta drops below 0.005 A/hr by hour 11-12
- Steady-state noise: power 18-52W (±53%), current 0.64-0.86A (±15%)

### Research Findings
- 13.3V is safe for FLA float charging (below 14.1V gassing threshold)
- No benefit to continued charging after curve flattens at 13.3V
- Industry standard: charge complete when current drops to 3-5% of Ah capacity
- FLA batteries should not sit below 12.4V — sulfation risk

### Edge Case Review (via Plan subagent)
Comprehensive review identified 15 edge cases ranked by severity:
- **HIGH:** Statistics cold start (unknown values), charger failure detection, Zigbee unavailability
- **MEDIUM:** HA restart mid-cycle, year boundary scheduling, premature flat detection, manual control
- **LOW/NEGLIGIBLE:** Long-term drift, timing drift, notification failures, already-charged batteries

All HIGH and MEDIUM issues were addressed in the implementation.

## Issues Encountered

- [Issue 1: API unreachable from container](issues/01-api-unreachable.md)
- [Issue 2: Initial plan over-engineered with helpers](issues/02-over-engineered-helpers.md)

## Follow-up Items

- **Restart HA** to load the new statistics sensors (required before automations will work)
- **Wait ~4 hours** for statistics sensors to populate with data
- **Verify sensors** in Developer Tools > States after population
- **First charge cycle** will be on the next Monday or Thursday at 6 AM — monitor notifications and automation trace
- **Tune flatness_threshold** after first cycle if stop time is too early/late (adjust from 0.03 in blueprint config)
- **Consider adding a battery voltage sensor** (e.g., via ESP32 ADC) for direct SOC monitoring in the future
- **Monitor steady-state current over months** — increasing values may indicate battery degradation
