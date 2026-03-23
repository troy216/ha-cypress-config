# Issue: Node-RED Flow Files Inaccessible

## What Happened
When trying to find references to `switch.grow_tower_pump` in Node-RED flows, couldn't locate the flow JSON files. Searched `/config`, `/addon_configs`, `/share`, and did a broad `find /` — no results.

## Impact
~3 minutes searching. Had to rely on indirect evidence (HA database saved_traces) to identify which automations reference the entity.

## Root Cause
Node-RED addon stores its data in its own Docker volume, not in `/config` or `/share`. The Claude Terminal addon container doesn't have access to other addons' data volumes.

## Resolution
Used the HA states API and database `states_meta` table to find `automation.tower_pump_on_every_15_minutes` and `automation.tower_pump_off_10_minutes_after_start`. Also found the reference in `/config/.storage/trace.saved_traces`. This was sufficient to identify the problem even without direct flow file access.

## Improvements
- **For Claude:** When investigating Node-RED flows, go straight to the HA API/database approach rather than searching the filesystem. Node-RED flow files are never accessible from this container.
- **For User:** The entity update must be done directly in the Node-RED UI — search for `grow_tower_pump` and update to `grow_tower_pump_2`.
