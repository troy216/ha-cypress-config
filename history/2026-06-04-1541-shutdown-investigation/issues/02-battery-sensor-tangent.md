# Issue: Battery Sensor Tangent

## What Happened

When investigating the unexpected shutdown, I started looking at battery-related entities (Enphase batteries, UPS sensors) instead of focusing on system logs. The user correctly interrupted and pointed out that battery devices wouldn't tell us anything about why HA went down - we needed to look at system logs.

## Impact

- ~5 minutes wasted exploring irrelevant sensors
- User had to redirect the investigation
- Demonstrated poor problem-solving prioritization

## Root Cause

1. **Misguided association:** User mentioned "power redundancy" including batteries, and I incorrectly associated this with needing to check battery sensor data
2. **Wrong problem framing:** The question was "why did the server shut down" not "was there a power outage"
3. **Bottom-up instead of top-down:** Started exploring available data instead of reasoning about what data would actually be useful

## Resolution

User explicitly said: "Why on earth are you looking for my batteries? You need to look at logs to see why HA went down. Battery devices are not going to tell you anything."

I immediately refocused on:
- System logs (host logs, supervisor logs, HA core logs)
- Previous boot kernel messages
- dmesg for hardware errors

## Improvements

### For Claude
- When investigating system issues, start with system-level logs, not application-level sensors
- Ask "what would this data actually tell me?" before exploring it
- For shutdown investigations, prioritize:
  1. Kernel logs / dmesg
  2. System journal (previous boot)
  3. Supervisor/Docker logs
  4. Application logs
- Entity data is useful for "what was the state" questions, not "why did hardware fail" questions

### Problem-Solving Discipline
- **Think before searching:** What log source would actually contain evidence of a system crash?
- **Top-down approach:** Start with the highest-level system logs (kernel, systemd) and work down
- **Question relevance:** "Would Enphase battery state data explain why a laptop powered off?" - obviously no
