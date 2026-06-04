#!/bin/bash
# Publish CPU temperatures to MQTT
# Run this periodically via cron or shell_command

MQTT_HOST="core-mosquitto"
MQTT_PORT="1883"

# Read temperatures
ACPI_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
CPU_TEMP=$(cat /sys/class/thermal/thermal_zone1/temp 2>/dev/null)

# Convert from millidegrees to degrees
ACPI_TEMP_C=$((ACPI_TEMP / 1000))
CPU_TEMP_C=$((CPU_TEMP / 1000))

# Publish to MQTT
mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "homeassistant/sensor/cpu_temperature/state" -m "$CPU_TEMP_C" 2>/dev/null
mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "homeassistant/sensor/acpi_temperature/state" -m "$ACPI_TEMP_C" 2>/dev/null

# Also publish discovery messages for auto-configuration
mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "homeassistant/sensor/cpu_temperature/config" -r -m "{\"name\": \"CPU Temperature\", \"state_topic\": \"homeassistant/sensor/cpu_temperature/state\", \"unit_of_measurement\": \"°C\", \"device_class\": \"temperature\", \"unique_id\": \"ha_host_cpu_temp\", \"icon\": \"mdi:thermometer\"}" 2>/dev/null
mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "homeassistant/sensor/acpi_temperature/config" -r -m "{\"name\": \"ACPI Temperature\", \"state_topic\": \"homeassistant/sensor/acpi_temperature/state\", \"unit_of_measurement\": \"°C\", \"device_class\": \"temperature\", \"unique_id\": \"ha_host_acpi_temp\", \"icon\": \"mdi:thermometer\"}" 2>/dev/null

echo "Published: CPU=${CPU_TEMP_C}°C, ACPI=${ACPI_TEMP_C}°C"
