# Session Report: Cielo Home Device Deletion

**Date:** 2026-02-11 09:57
**Session ID:** bfc1ac5b-ecf0-41e1-8b60-e38ad3c9cb93
**Duration:** ~15 minutes (estimated)

## Summary

Added `async_remove_config_entry_device()` to the Cielo Home custom integration to enable the "Delete" button on device pages in the Home Assistant UI. The user needed to delete and re-add the Bedroom AC device to reset entity names that the built-in "Rename entity" feature wasn't fixing across 9 entities.

## Goals

- Enable per-device deletion in the Cielo Home integration (which lacked this standard HA hook)
- Allow the user to delete the Bedroom AC device and let it be re-discovered with clean default entity names on integration reload

## Changes Made

### `/config/custom_components/cielo_home/__init__.py`

Added the `async_remove_config_entry_device` function (lines 89-93) between `async_unload_entry` and `update_listener`:

```python
async def async_remove_config_entry_device(
    hass: HomeAssistant, entry: ConfigEntry, device_entry
) -> bool:
    """Allow device removal from the UI."""
    return True
```

This is a standard Home Assistant integration hook. When present and returning `True`, HA displays a "Delete" button on each device page for the integration. HA handles all registry cleanup (device + entities) automatically.

## Key Decisions

### 1. Local patch only (no upstream PR)

- **Decided:** Apply the fix locally without submitting a PR to bodyscape/cielo_home
- **Alternatives:** (a) Local patch + upstream PR, (b) One-time registry file edit, (c) Remove/re-add entire integration
- **Rationale:** User chose the simplest option. The upstream repo's issue #70 was closed without a fix (maintainer suggested removing the whole integration). A HACS update will overwrite this change, but the 5-line patch is trivial to re-apply.

### 2. Unconditional `return True`

- **Decided:** No filtering or confirmation logic in the removal handler
- **Alternatives:** Could filter by device state, add logging, etc.
- **Rationale:** YAGNI. Deleted devices automatically reappear on integration reload since the API returns all devices. No risk of permanent data loss.

## Technical Details

### Investigation

- Explored the full Cielo Home integration codebase (`/config/custom_components/cielo_home/`)
- Confirmed no existing device removal mechanism (`async_remove_config_entry_device` was missing)
- Found 7 registered devices with 77 total entities across the integration
- Checked upstream GitHub: issue #70 ("Remove Cielo device") was closed without code fix
- Confirmed integration is HACS-managed (bodyscape/cielo_home v1.8.9)

### How the fix works

1. HA detects `async_remove_config_entry_device` exists in the integration module
2. HA shows "Delete" button on each Cielo Home device page
3. On delete: HA removes device + all associated entities from `.storage/core.device_registry` and `.storage/core.entity_registry`
4. On integration reload: API returns all devices including the deleted one, which gets re-created with fresh default entity names

## Issues Encountered

No significant issues. The session was straightforward.

## Follow-up Items

- **User action needed:** Reload Cielo Home integration, delete Bedroom device, reload again to re-discover it with clean names
- **Future consideration:** If the upstream repo ever adds this function natively, the local patch becomes redundant (and would be overwritten by HACS update anyway)
- **HACS update awareness:** After any HACS update to Cielo Home, check if the delete button still works; re-apply the patch if needed
