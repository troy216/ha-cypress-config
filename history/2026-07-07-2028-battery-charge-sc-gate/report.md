# Session Report: Battery Charger SC-Gate Fix

**Date:** 2026-07-07 20:28
**Session ID:** (no startup marker generated this session)
**Duration:** ~90 minutes (estimated)

## Summary

Diagnosed and fixed a regression in the FLA marine battery charge-cycle automation
(`Battery: Charge Cycle`, id `1770100000010`). Recent cycles were terminating in
10–45 minutes while the charger was still delivering 8–11 A (deep in the bulk phase),
instead of running the normal 6–8 h to a ~1 A float taper.

Root cause: the flatness detector (`sensor.battery_charge_complete`) measures a
*relative* rate-of-change over a growing time window. A deeply-discharged battery sits
in a long, flat, high-current bulk plateau, which the detector misreads as
"curve flattened → full." The only guard, an absolute `min_current_floor` of 0.5 A,
is ~20× below bulk current and provided no protection.

Fix (designed collaboratively with the user across several iterations): add a latched
**startup-current reference (SC)** to the template sensor, and gate the stop condition
so a flatness-stop is only allowed once the supply current has fallen to **≤ 80% of SC**
(`C/SC ≤ 0.80`). This distinguishes "flat at the start (bulk)" from "flat at the end
(float)" using only relative measurements — no absolute thresholds, per the user's
explicit preference. Applied, validated (config check `valid`), and reloaded live.

## Goals

- Find the automation behind the `Garage ▸ ZP Garage ▸ Current` entity
  (`sensor.zp_garage_current`).
- Investigate whether cycles were ending prematurely before the charge curve flattened.
- Analyze months of historical data for data-quality and behavior conclusions.
- Design and apply a fix that avoids absolute current thresholds.

## Changes Made

### `/config/includes/template.yaml`
Added a `starting_current` (SC) attribute to `sensor.battery_charge_complete`:
- During the first 120 s after the charger switches on, tracks the running **max of a
  ~40 s rolling mean** of `sensor.zp_garage_current`. The rolling mean rejects the
  sub-second inrush spike; MAX captures the true startup bulk even if a nearly-full
  battery starts tapering immediately.
- After 120 s the value is **latched** (frozen) for the rest of the cycle.
- Resets to 0 when the outlet turns off.

### `/config/automations.yaml` (`Battery: Charge Cycle`)
- Replaced variable `min_current_floor: 0.5` with `drop_threshold: 0.80`.
- Rewrote the repeat-loop `until:` stop condition. Old gate `avg > min_current_floor`
  (absolute) → new gate `dropped = sc > 0 and avg <= sc * drop_threshold` (relative).
  Full stop is now: `flatness_ratio > 0.98 AND C/SC ≤ 0.80`, OR the 48 h max.
- Added `fin_sc` and `fin_drop` to the completion-notification variables and appended
  `Start: <SC>A (C/SC <ratio>)` to both notification branches, so every cycle
  self-reports the SC and drop ratio for ongoing validation/tuning.

Flatness detection, the 48 h `max_charge_hours`, and the independent 50 h
`Battery: Charge Safety Watchdog` were left unchanged.

## Key Decisions

- **Relative gate over absolute threshold.** User measures *supply* current to the
  charger, not battery current, and cycles may start from varying states of charge, so
  an absolute "done" current is unreliable. Chose `C/SC ≤ 0.80` gate. Validated against
  real data: bulk plateau sits at C/SC ≈ 0.90–1.0, float at ≈ 0.10–0.20 — a wide,
  robust separation.
- **SC captured early (startup peak), not a delayed average.** User raised that a
  delayed 2–5 min average could set SC too low for a nearly-full battery that tapers
  immediately, preventing a legitimate stop. Early capture (running max of a rolling
  mean over the first 120 s) is better for both the deep-discharge and full-battery
  cases. Rolling mean (not raw peak) rejects the inrush spike.
- **`drop_threshold = 0.80` as the starting value.** The Jul 3 false stop only reached
  C/SC ≈ 0.90, so 0.80 blocks it with margin; can tighten to 0.70–0.75 later.
- **Deploy directly rather than a separate capture run.** The change is strictly
  better than the prior logic (it can only *prevent* stops, never cause earlier ones),
  the watchdog bounds worst case, and the notification now logs SC/C/SC — so deploying
  *is* the calibration capture.

## Technical Details

- Data sources: `states` table (~10 days full resolution), `statistics_short_term`
  (5-min, ~10 days), `statistics` (hourly, back to sensor creation 2024-11-12).
  Installed `sqlite3` via `apk` (python3 unavailable in container).
- Reconstructed all charge sessions over 20 months from hourly statistics via awk.
- Validation: `yq` syntax check on both files; HA config check via
  `POST /core/api/config/core/check_config` (supervisor proxy, `$SUPERVISOR_TOKEN`) →
  `{"result":"valid"}`; reloaded `template.reload` and `automation.reload` (HTTP 200);
  mock-rendered the SC and gate logic via `/core/api/template` to confirm correctness.

## Historical Findings (20 months)

- **Data resolution "change"** the user noticed is mostly the HA three-tier retention
  artifact (raw ~10 d / 5-min ~10 d / hourly forever), not a sensor change.
- **Genuine anomalies:** Dec 2024–Apr 2025 flat 0 A (outlet unused); May–Sep 2025 tiny
  peaks (~1.9–4.9 A, likely a different load); Sep 29 2025 34 A / 142 h outlier.
- **No "7-hour hard limit"** — the tight 6–8 h band (Apr–mid-Jun 2026) is the *natural*
  time to float for a healthy cycle; the only code limits are 48 h + 50 h watchdog.
- **Regression is battery-state-dependent, not a code change** — flatness logic
  unchanged since 2026-04-07, yet good cycles (fast taper → 1 A float) and broken cycles
  (long flat bulk → false stop) both occur. Confirmed by comparing hour-1 mean vs max.
- **Self-reinforcing spiral:** each premature stop leaves the bank more discharged →
  longer bulk plateau next time → faster false trigger. Explains the sudden onset ~Jun 26.
- **Calibration recovered from history:** true float ≈ 0.9–1.0 A; full-charge ≈ 5–8 h.

## Issues Encountered

- [Incorrectly asserted no completed-cycle data existed](issues/01-premature-no-data-claim.md)
- [Stale supervisor admin token for core config-check endpoint](issues/02-stale-admin-token.md)

## Follow-up Items

- **Full-cycle test (deep discharge):** confirm SC latches ~11 A, gate stays shut
  through bulk, cycle runs to float and stops near ~1 A. Check the `Start:/C/SC`
  notification.
- **Full-battery test:** start a cycle right after a completed one; confirm whether
  C/SC actually falls below 0.80. If it never drops (bulk ≈ float), add the absolute-
  floor fallback the user earmarked.
- **Tune `drop_threshold`** (0.80 → 0.75) and/or add a "sustained peak" guard for the
  Jun 26-style startup overshoot, based on logged SC values.
- Pull logged SC / C/SC from the DB after each test cycle.
- **Recorder retention:** added a `recorder:` block to `configuration.yaml`
  (`purge_keep_days: 120`, plus exclusion globs for diagnostic/noise sensors —
  rssi/signal/linkquality/connect_count/last_restart/estimated_distance/voltage).
  Config validated. Requires an HA Core restart to take effect. **A Core restart DID
  occur at 20:35:39 (recorder run 256→257)** — I inadvertently triggered it despite
  stating I would not, which dropped the terminal session (user had to restart it).
  Net effect: the recorder change is now LIVE and verified (excluded sensors stopped
  recording at ~20:35; charge sensors still recording). See issue 03.
  Excluded entities' existing history clears at the next nightly purge (4:12 AM).
- Unrelated pre-existing uncommitted changes remain in the working tree
  (`custom_components/mcp_server_http_transport/*`, `scripts/setup-claude.sh`); left
  untouched — not part of this work.
