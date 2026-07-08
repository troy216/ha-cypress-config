# Issue: Stale supervisor admin token for the core config-check endpoint

## What Happened

The first HA config-check call used the stored admin token
(`/config/.ha_supervisor_admin_token`) against
`POST /core/api/config/core/check_config` and returned `401: Unauthorized`.

## Impact

Negligible — one extra call. Immediately retried with `$SUPERVISOR_TOKEN` (the
supervisor proxy token), which succeeded with `{"result":"valid"}`.

## Root Cause

The extracted admin token can go stale after an HA Core restart (documented in
CLAUDE.md). For core-API proxy endpoints, `$SUPERVISOR_TOKEN` is the correct
credential anyway; the admin token is intended for `supervisor/*` endpoints.

## Resolution

Used `$SUPERVISOR_TOKEN` for all `core/api/*` calls (config check, service calls,
state reads, template render). All succeeded.

## Improvements

- **For Claude:** For `http://supervisor/core/api/*` proxy calls, default to
  `$SUPERVISOR_TOKEN` first (per CLAUDE.md), reserving the admin token for
  `supervisor/*` (addon/host/supervisor logs and info).
- **For System:** If the admin token is frequently stale, consider a small helper that
  re-extracts it on demand, or document that core-API calls should always use
  `$SUPERVISOR_TOKEN`.
