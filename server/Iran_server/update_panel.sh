#!/bin/bash
DATA=$(vnstat -i eth0 --oneline b 2>/dev/null)
RX=$(echo "$DATA" | awk -F';' '{print $9}')
TX=$(echo "$DATA" | awk -F';' '{print $10}')
if [[ -n "$RX" && -n "$TX" && "$RX" -gt 0 ]]; then
  RATIO=$(awk -v rx="$RX" -v tx="$TX" 'BEGIN {printf "%.2f", tx/rx}')
else
  RATIO="N/A"
fi
CITY_STATUS=$(systemctl is-active chisel || echo inactive)
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
</body>
</html>
EOT

