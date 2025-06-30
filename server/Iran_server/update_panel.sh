#!/bin/bash
set -euo pipefail

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
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Server Panel</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      min-height: 100vh;
      background: linear-gradient(135deg, #232526, #414345 80%);
      margin: 0;
      font-family: 'Segoe UI', 'Tahoma', 'Geneva', Verdana, sans-serif;
      color: #f2f2f2;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
    }
    .panel {
      background: rgba(30, 30, 30, 0.93);
      box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.17);
      border-radius: 20px;
      padding: 2.5rem 2rem 2rem 2rem;
      min-width: 320px;
      max-width: 95vw;
      margin-top: 2rem;
      text-align: center;
    }
    h1 {
      margin-top: 0.3em;
      margin-bottom: 0.7em;
      font-size: 2.2em;
      letter-spacing: 1px;
      font-weight: 800;
      color: #43e97b;
      text-shadow: 0 0 5px #222b, 0 2px 8px #43e97b44;
    }
    h2 {
      color: #ffd166;
      margin-bottom: 0.5em;
      font-size: 1.2em;
      margin-top: 1.5em;
      letter-spacing: 0.5px;
    }
    .stat {
      font-size: 1.08em;
      margin: 0.4em 0;
      padding: 0.4em 0;
      border-bottom: 1px solid #2c2c2c33;
    }
    .ratio {
      color: #43e97b;
      font-weight: bold;
    }
    .city-status {
      font-weight: bold;
      color: ${CITY_STATUS} == "active" ? "#00e676" : "#ff5252";
    }
    .connected {
      color: #00e676;
      font-weight: bold;
      font-size: 1.15em;
    }
    .disconnected {
      color: #ff5252;
      font-weight: bold;
      font-size: 1.15em;
    }
    @media (max-width: 600px) {
      .panel { min-width: unset; padding: 1rem;}
      h1 { font-size: 1.2em;}
      h2 { font-size: 1em;}
    }
  </style>
</head>
<body>
  <div class="panel">
    <h1>Server Traffic Usage</h1>
    <div class="stat">RX: <b>${RX}</b> bytes</div>
    <div class="stat">TX: <b>${TX}</b> bytes</div>
    <div class="stat">TX/RX Ratio: <span class="ratio">${RATIO}</span></div>
    <h2>City Link Client Status</h2>
    <div class="stat city-status">$CITY_STATUS</div>
    <h2>Reverse Tunnel</h2>
    <div class="stat ${CONNECTION_STATE}">$CONNECTION_STATE</div>
  </div>
</body>
</html>
EOT

