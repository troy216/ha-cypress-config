---
state: alignment
---
<!--
═══════════════════════════════════════════════════════════════════════════
ITEM.MD - PURE USER INTENT
═══════════════════════════════════════════════════════════════════════════

This file captures WHAT the user wants and WHY, not HOW to build it.

This file is IMMUTABLE after alignment phase.
═══════════════════════════════════════════════════════════════════════════
-->

# Chrome DevTools MCP and Headless Chromium

## User Intent

Install headless Chromium and the `chrome-devtools-mcp` npm package inside the Claude Terminal add-on container so that Claude can interact with the Home Assistant UI programmatically — navigating pages, clicking elements, filling forms, taking screenshots, and inspecting the DOM and network activity.

This gives Claude visual and interactive access to the HA frontend, enabling UI-level troubleshooting, verification of dashboard changes, and automated interaction with the HA web interface without requiring the user to manually describe what they see.

## Assumptions & Reasoning

- **Headless mode only**: The container has no display server. Chromium must run in headless mode (`--headless=new`). This is sufficient since the goal is programmatic interaction, not visual use by a human.

- **APK install with caching**: Chromium will be installed via `apk add` using the existing apk-cache pattern already established in `/data/init-tools.sh`. This ensures the package persists across container restarts without re-downloading.

- **NPM MCP server to `/data/`**: The `chrome-devtools-mcp` npm package will be installed under `/data/` (persistent volume) so it survives container restarts. The MCP server will be configured to launch on-demand via Claude's MCP configuration.

- **HA UI accessible via Supervisor proxy**: The HA frontend is reachable from this container at `http://supervisor/core/` (or similar Supervisor-proxied path), using `$SUPERVISOR_TOKEN` for authentication. Direct access to `192.168.1.2:8123` is not available from this container.

- **No GPU acceleration needed**: Software rendering is acceptable for headless screenshot and DOM interaction use cases.

## Success Criteria

- [ ] Chromium is launchable in headless mode inside the container
- [ ] The `chrome-devtools-mcp` MCP server is installed and configured
- [ ] Claude can launch the MCP server and connect to a headless Chromium instance
- [ ] Claude can navigate to the HA UI and take a screenshot
- [ ] The setup persists across container restarts (via `/data/` caching)
