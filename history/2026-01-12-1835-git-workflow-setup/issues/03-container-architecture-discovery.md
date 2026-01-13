# Issue: Container Architecture Discovery Took Extended Time

## What Happened
When planning how to install git and other tools, I initially proposed a simple `apk add` approach. The user asked important clarifying questions:
- "Is Claude Terminal in the same context as HA OS?"
- "Do you inherit tools from the main HAOS?"

This revealed I didn't understand the container architecture. I had to launch multiple exploration agents to research:
1. Whether this was an isolated Docker container
2. What paths persist across restarts
3. Whether `apk add` packages would persist
4. How to properly set up persistent tools

The research revealed:
- Claude Terminal is a fully isolated Alpine Linux container
- Only `/data/` and `/config/` persist
- Packages installed via `apk add` are lost on container restart
- The solution required cached package installation

## Impact
- **Time spent:** ~20 minutes on architecture research
- Multiple agent invocations to explore the environment
- Had to revise the implementation plan after discovering persistence limitations

## Root Cause
1. **Claude-side:** I made assumptions about the environment without verifying:
   - Assumed packages would persist
   - Didn't initially understand HA add-on container isolation
2. **Missing documentation:** The initial CLAUDE.md didn't document the container architecture
3. **Necessary discovery:** This information wasn't available upfront and needed to be researched

## Resolution
- Thoroughly researched the container architecture
- Implemented cached APK installation (`/data/apk-cache/`)
- Documented the architecture in CLAUDE.md for future sessions
- Created init script that reinstalls tools quickly using cache

## Improvements

### For Claude
- When working in a new environment, proactively investigate:
  - What persists across restarts?
  - Is this containerized? If so, what's the base image?
  - What tools are pre-installed vs need installation?
- Ask these questions early rather than assuming

### For User
- The questions asked ("Is this isolated?", "Do you inherit tools?") were exactly right
- Continuing to challenge assumptions helps catch issues early

### For System
- Now documented in CLAUDE.md Environment section
- Future sessions will have this context immediately
- This issue is a success story: initial gap → user questions → research → documentation
