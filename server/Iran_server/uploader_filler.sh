#!/bin/bash
RX=$(cat /sys/class/net/eth0/statistics/rx_bytes)
TX=$(cat /sys/class/net/eth0/statistics/tx_bytes)
DIFF=$(( RX - TX ))

if [ "$DIFF" -gt 1048576 ]; then
  head -c "$DIFF" /dev/urandom | \
    curl -m 20 --silent --upload-file - https://transfer.sh/$$.bin >/dev/null
fi
