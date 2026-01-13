# Home Assistant Configuration

This is a **Home Assistant installation** (v2026.1.0) with 13 custom integrations and automation blueprints. Home Assistant is a Python-based open-source home automation platform using YAML configuration and Python extensions.

**Key Components:**
- Primary Language: YAML (configuration) + Python (custom integrations)
- Data Storage: SQLite (home-assistant_v2.db, zigbee.db)
- Protocol Support: MQTT, Zigbee, WebSocket, HTTP, BLE

## Directory Structure

```
/config/
├── configuration.yaml           # Main HA configuration
├── automations.yaml            # Automation rules
├── scripts.yaml                # Reusable script actions
├── secrets.yaml                # Credentials (gitignored)
├── custom_components/          # 13 custom integrations
│   ├── hacs/                   # Community Store manager
│   ├── nodered/                # Node-RED integration
│   ├── bambu_lab/              # 3D printer control
│   ├── tesla_custom/           # Tesla vehicle integration
│   ├── eufy_security/          # Security system
│   └── ...
├── blueprints/                 # Reusable automation templates
├── esphome/                    # ESPHome device configs
├── shell/                      # Deployment scripts
└── .storage/                   # HA runtime state (gitignored)
```

## Key Custom Integrations

| Component | Purpose | Version |
|-----------|---------|---------|
| hacs | Community package manager | 2.0.5 |
| nodered | Node-RED automation bridge | 4.2.2 |
| bambu_lab | 3D printer control | 2.2.19 |
| tesla_custom | Tesla vehicle | 3.24.3 |
| eufy_security | Security cameras | 8.2.2 |
| zha_toolkit | Zigbee network tools | v1.1.24 |

## Architecture Patterns

### Integration Entry Points
Each component has a `manifest.json` defining domain, dependencies, config_flow support, and iot_class. The main entry point is `__init__.py` with `async_setup_entry()`.

### Entity Discovery Pattern
```python
async def async_setup_entry(hass, config_entry, async_add_entities):
    async def async_discover(config, connection):
        await _async_setup_entity(hass, config, async_add_entities)
    config_entry.async_on_unload(
        async_dispatcher_connect(hass, DISCOVERY_SIGNAL, async_discover)
    )
```

### Coordinator Pattern
Most device integrations use `DataUpdateCoordinator` for data fetching and caching:
```python
class MyDataUpdateCoordinator(DataUpdateCoordinator):
    async def _async_update_data(self):
        # Fetch from device/API, notifies all listening entities
```

### Platform Registration
```python
PLATFORMS = ["sensor", "switch", "binary_sensor", "climate", "fan"]
await hass.config_entries.async_forward_entry_setups(entry, PLATFORMS)
```

## Custom Integration Development

### Required Files
- `__init__.py` - Integration setup with `async_setup_entry()`
- `manifest.json` - Domain, version, dependencies, config_flow
- `config_flow.py` - UI-based configuration (if config_flow: true)
- Platform files: `sensor.py`, `switch.py`, etc.
- `services.yaml` - Custom service definitions (optional)

### Validation Rules (HACS)
Located in `custom_components/hacs/validate/`:
- One file per rule
- Use `ActionValidationBase` as base class
- Use `validate` or `async_validate` methods
- Raise `ValidationException` on failure

## Configuration Patterns

### YAML Templating
Jinja2 templates in entities:
```yaml
value_template: "{{ states('sensor.xxx') }}"
```

### Secrets Reference
```yaml
api_key: !secret my_api_key
```

## API Reference

| Endpoint | Description |
|----------|-------------|
| `/api/` | API status check |
| `/api/config` | HA configuration info |
| `/api/states` | All entity states |
| `/api/states/<entity_id>` | Single entity state |
| `/api/services/<domain>/<service>` | Call a service (POST) |
| `/api/error_log` | Error log contents |
| `/api/history/period/<timestamp>` | Historical data |
| `/api/logbook/<timestamp>` | Logbook entries |

## Testing Changes

Home Assistant does not have a built-in CLI test command. Changes are tested by:
1. Editing configuration/integration files
2. Validating configuration via HA UI (Developer Tools > YAML > Check Configuration)
3. Restarting Home Assistant via UI or API
4. Checking logs for errors

## Deployment

Configuration is backed up to GitHub via shell integration:
```bash
/config/shell/git-push-config.sh
```

Called via Home Assistant `shell_command.git_push_config` service.

## Files to Never Commit

Per `.gitignore`:
- `secrets.yaml` - Credentials
- `.storage/` - Runtime state
- `*.db*` - SQLite databases
- `.cloud/` - Cloud connection state
