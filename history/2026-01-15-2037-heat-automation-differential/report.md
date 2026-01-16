# Session Report: Heat Automation Differential Trigger

**Date:** 2026-01-15 20:37
**Session ID:** 1efbc453-f0a8-4ebb-8f6f-6438238d2698
**Session Marker:** SESS-cee86456f50a
**Duration:** ~10 minutes

## Summary

Updated two Home Assistant automations ("Move heat on" and "Move heat off") to trigger based on temperature differential between the bedroom AC unit and a separate bedroom temperature sensor, rather than absolute temperature thresholds.

## Goals

- Change "Move heat on/off" automations from absolute temperature triggers (above/below 65°F) to differential-based triggers
- Trigger ON when bedroom AC temperature is 3°F or more above the bedroom sensor temperature
- Trigger OFF when the differential falls below 3°F

## Changes Made

### `/config/automations.yaml`

**Move heat on automation** (id: `1768199536019`):
- **Before:** Device trigger on `climate.bedroom` current temperature above 65°F
- **After:** Template trigger comparing temperatures:
  ```yaml
  triggers:
  - trigger: template
    value_template: >-
      {{ state_attr('climate.bedroom', 'current_temperature') | float(0) >=
         states('sensor.bedroom_sensor_temperature') | float(0) + 3 }}
  ```

**Move heat off automation** (id: `1768200924978`):
- **Before:** Device trigger on `climate.bedroom` current temperature below 65°F
- **After:** Template trigger:
  ```yaml
  triggers:
  - trigger: template
    value_template: >-
      {{ state_attr('climate.bedroom', 'current_temperature') | float(0) <
         states('sensor.bedroom_sensor_temperature') | float(0) + 3 }}
  ```

Both automations retained their original action blocks (turning a switch on/off via device_id).

## Key Decisions

### Template Trigger vs Numeric State Trigger
- **Chosen:** Template trigger with Jinja2 comparison
- **Alternative:** Could have used `numeric_state` trigger with `value_template` attribute
- **Rationale:** Template triggers are more flexible for comparing two dynamic values and are cleaner for differential calculations

### Float Filter with Default
- Used `| float(0)` to handle potential unavailable/unknown states gracefully
- Prevents automation errors if either sensor temporarily becomes unavailable

## Technical Details

### Entities Involved
- **AC Temperature Source:** `climate.bedroom` → `current_temperature` attribute (was 69°F)
- **Reference Sensor:** `sensor.bedroom_sensor_temperature` (was 67.28°F)
- **Controlled Switch:** Device ID `bb21fcfcc913e431866a0b4452166426`, Entity ID `7b6575f5396e01f68bcab3e3a647afe9`

### Commands Run
1. Searched for automations: `grep -i "move heat" automations.yaml`
2. Queried HA API for entity states to identify correct sensors
3. Validated configuration: `POST /api/config/core/check_config` → valid
4. Reloaded automations: `POST /api/services/automation/reload`

### Commit
- **Hash:** `937f08e`
- **Message:** "Update Move heat automations to use temperature differential trigger"

## Issues Encountered

No significant issues. The session was straightforward with one minor clarification needed:

- Initial uncertainty about which climate entity was "AC temp" - resolved when user clarified it was the entity already in the automation (bedroom area) → `climate.bedroom`

## Follow-up Items

- Monitor automation behavior to confirm triggers work as expected
- User may want to adjust the 3°F threshold in the future based on real-world performance
- Consider adding a condition to prevent rapid cycling if temperatures hover near the threshold (hysteresis)
