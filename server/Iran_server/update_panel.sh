#!/bin/bash

# Network interface to monitor. Can be overridden by setting the NL_INTERFACE
# environment variable before running this script.
INTERFACE="${NL_INTERFACE:-eth0}"

DATA=$(vnstat -i "$INTERFACE" --oneline b 2>/dev/null)
RX=$(echo "$DATA" | awk -F';' '{print $9}')
TX=$(echo "$DATA" | awk -F';' '{print $10}')
if [[ -n "$RX" && -n "$TX" && "$RX" -gt 0 ]]; then
  RATIO=$(awk -v rx="$RX" -v tx="$TX" 'BEGIN {printf "%.2f", tx/rx}')
else
  RATIO="N/A"
fi
CITY_STATUS=$(systemctl is-active chisel || echo inactive)
REVERSE_STATE=$(ss -ntp 2>/dev/null | grep chisel | grep ESTAB)
if [[ -n "$REVERSE_STATE" ]]; then
  CONNECTION_STATE="connected"
else
  CONNECTION_STATE="disconnected"
fi
cat >/var/www/panel/index.html <<EOT
<!DOCTYPE html>
<html>
<head><title>Server Panel</title></head>
<body>
<h1>Server Traffic Usage</h1>
<p>RX: ${RX} bytes</p>
<p>TX: ${TX} bytes</p>
<p>TX/RX Ratio: ${RATIO}</p>
<h2>City Link Client Status</h2>
<p>${CITY_STATUS}</p>
<h2>Reverse Tunnel</h2>
<p>${CONNECTION_STATE}</p>
</body>
</html>
EOT

