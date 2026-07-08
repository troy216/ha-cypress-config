# Issue: Prematurely claimed no completed-cycle calibration data existed

## What Happened

While designing the fix, I repeatedly told the user we had "zero completed-cycle data"
to calibrate the thresholds against, and proposed running a special uninterrupted
capture cycle to obtain it. This was based only on the `states` table, which retains
~10 days — and every cycle in that window happened to be a broken (premature) one.

The user then suggested looking further back. Checking the long-term `statistics`
table revealed 20 months of hourly data, including dozens of *completed* cycles that
tapered cleanly to ~1 A float. The calibration data (float level, full-charge time)
existed all along.

## Impact

- Would have led to an unnecessary special "disable the stop and capture" run.
- Understated confidence in the fix; the historical completions both confirmed the
  diagnosis and supplied the float/timing calibration directly.
- Minor wasted reasoning; caught quickly once the user prompted.

## Root Cause

Claude assumption: treated the `states` table (10-day retention) as the full extent of
available history without checking the long-term statistics tables. For any HA sensor
with `state_class: measurement`, hourly statistics persist far longer and should be the
first place to look for multi-month analysis.

## Resolution

Queried `statistics` / `statistics_meta`, reconstructed all sessions, and corrected the
claim. The historical completions became the calibration basis, and the special capture
run was downgraded to "the deployed fix logs its own data."

## Improvements

- **For Claude:** When asked about historical trends beyond ~10 days for an HA sensor,
  check `statistics` (hourly) and `statistics_short_term` (5-min) *before* asserting
  data limits. Aligns with the existing memory note
  `feedback_verify_before_asserting` — verify against the actual data source before
  making a claim about what data does/doesn't exist.
- **For System:** Worth noting in CLAUDE.md's API section that long-term statistics are
  the source for multi-month sensor analysis, distinct from the short-lived `states`.
