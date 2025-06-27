#!/bin/bash

# This helper script attempts to keep upstream and downstream bandwidth usage
# closer together by sending dummy data when inbound traffic far exceeds
# outbound traffic.  Random bytes are uploaded to transfer.sh, which is a
# free temporary file sharing service.  Only when the received amount is more
# than 1 MB greater than the transmitted amount will the upload occur.

RX=$(cat /sys/class/net/eth0/statistics/rx_bytes)
TX=$(cat /sys/class/net/eth0/statistics/tx_bytes)
DIFF=$(( RX - TX ))

if [ "$DIFF" -gt 1048576 ]; then
  head -c "$DIFF" /dev/urandom | \
    curl -m 20 --silent --upload-file - https://transfer.sh/$$.bin >/dev/null
fi
