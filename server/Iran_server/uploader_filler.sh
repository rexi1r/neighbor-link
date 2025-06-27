#!/bin/bash

# This helper script attempts to keep upstream and downstream bandwidth usage
# closer together by sending dummy data when inbound traffic greatly exceeds
# outbound traffic.  Random bytes are uploaded to transfer.sh, which is a free
# temporary file sharing service.

STATE_FILE=/var/tmp/uploader_filler_state

# Network interface to monitor. Can be overridden by setting the NL_INTERFACE
# environment variable before running this script.
INTERFACE="${NL_INTERFACE:-eth0}"

RX=$(cat "/sys/class/net/${INTERFACE}/statistics/rx_bytes")
TX=$(cat "/sys/class/net/${INTERFACE}/statistics/tx_bytes")

if [ ! -f "$STATE_FILE" ]; then
  echo "$RX $TX" > "$STATE_FILE"
  exit 0
fi

read -r PREV_RX PREV_TX < "$STATE_FILE"

RX_DIFF=$(( RX - PREV_RX ))
TX_DIFF=$(( TX - PREV_TX ))

# Guard against counter reset
if [ "$RX_DIFF" -lt 0 ]; then RX_DIFF=0; fi
if [ "$TX_DIFF" -lt 0 ]; then TX_DIFF=0; fi

# Only upload when 80% of received traffic is still greater than transmitted
if [ $(( RX_DIFF * 8 / 10 )) -gt "$TX_DIFF" ]; then
  DIFF=$(( RX_DIFF - TX_DIFF ))
  if [ "$DIFF" -gt 0 ]; then
    head -c "$DIFF" /dev/urandom | \
      curl -m 20 --silent --upload-file - https://transfer.sh/$$.bin >/dev/null
  fi
fi

echo "$RX $TX" > "$STATE_FILE"
