#!/bin/bash
# Disable aggressive head parking on HDD
# Run at boot to prevent excessive load cycles

docker run --rm --privileged -v /dev:/dev alpine sh -c "
apk add --no-cache hdparm >/dev/null 2>&1
hdparm -B 254 -S 0 /dev/sda >/dev/null 2>&1
"
echo "Disk APM set to 254 (max performance)"
