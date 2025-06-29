#!/bin/sh


LOGFILE=/var/log/chisel.log
PROCESS_LOG="/var/log/chisel_process.log"

init_process_log() {
    [ -f "$PROCESS_LOG" ] || { touch "$PROCESS_LOG" && chmod 600 "$PROCESS_LOG"; }
    if [ $(stat -c%s "$PROCESS_LOG" 2>/dev/null || echo 0) -gt 1000000 ]; then
        mv "$PROCESS_LOG" "$PROCESS_LOG.1" 2>/dev/null
        touch "$PROCESS_LOG" && chmod 600 "$PROCESS_LOG"
    fi
}

log_msg() {
    init_process_log
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$PROCESS_LOG"
}

if [ "$1" == "outline" ];then
    LOGFILE=/var/log/outline-gate.log
fi

# Indicate detection check
log_msg "Checking status from $LOGFILE"

# Exit early if the log file hasn't been created yet
if [ ! -f "$LOGFILE" ]; then
    echo "unknown"
    log_msg "Log file $LOGFILE missing"
    exit 0
fi

# Filter log lines containing "Connect" (case-insensitive)
last_status=""
# Use a while loop to read each line from the grep output
while IFS= read -r line; do
    
    HAS_CONNECTED=$(echo "$line" | grep "Connected")
    HAS_CONNECTING=$(echo "$line" | grep "Connecting")

    if [ ! -z "$HAS_CONNECTED" ]; then
        last_status="Connected"
    elif [ ! -z "$HAS_CONNECTING" ]; then
        last_status="Connecting"
    else
        last_status="other"
    fi

done < <(grep -i "Connect" $LOGFILE)

echo "$last_status"
log_msg "Status result: $last_status"
