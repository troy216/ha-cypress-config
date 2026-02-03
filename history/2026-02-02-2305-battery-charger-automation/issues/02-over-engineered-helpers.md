# Issue: Initial Plan Over-Engineered with Helper Entities

## What Happened
The first plan design included 7 helper entities:
- `input_boolean.battery_charging_active` — charge state tracking
- `input_number.battery_current_previous` — stored previous current reading
- `input_number.battery_slope_flat_count` — consecutive flat reading counter
- `input_datetime.battery_charge_start_time` — cycle start time
- `input_number.battery_slope_threshold` — tunable threshold
- `input_number.battery_min_charge_hours` — tunable min time
- `input_number.battery_max_charge_hours` — tunable max time

The user pushed back, correctly noting that:
1. The charge state could be tracked by the outlet switch state directly
2. Previous current readings could be avoided by using two statistics sensors
3. Configuration values belong in blueprint inputs, not disconnected helpers
4. The flat counter was unnecessary with the convergence approach

## Impact
First plan revision was rejected. Required a redesign that eliminated all helpers. The final design is simpler and more maintainable.

## Root Cause
Claude defaulted to a "state machine" pattern using helpers for state tracking, which is common in HA automations but was unnecessary here. The slope detection algorithm was initially designed around hourly delta computation (requiring stored previous values) rather than the simpler moving-average-convergence approach.

## Resolution
Redesigned to use:
- Two statistics sensors (1h and 4h means) — replaces stored previous values and flat counter
- Outlet switch state — replaces `input_boolean.battery_charging_active`
- Blueprint inputs — replaces `input_number` configuration helpers
- `repeat/until` loop with inline variables — replaces the need for persistent state

## Improvements
- **For Claude:** When designing HA automations, prefer approaches that derive state from existing entities rather than creating helpers. Ask: "Can I infer this state from something that already exists?" before adding a helper.
- **For Claude:** When users say they don't like disconnected helpers, take that seriously as a design constraint from the start.
- **For Claude:** The moving-average-convergence approach should have been the first choice — it's simpler, more robust, and better known in signal processing than the hourly-delta-with-counter approach.
