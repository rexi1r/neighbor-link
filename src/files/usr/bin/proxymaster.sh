#!/bin/sh
# Define the file name and the URL to download from
CHISEL_BIN="/usr/bin/chisel"
FILE="/tmp/chisel"
# Use system chisel if available
[ -x "$CHISEL_BIN" ] && FILE="$CHISEL_BIN"
# Log file for process events
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
# Determine architecture for chisel download
ARCH_RAW=$(uname -m)
case "$ARCH_RAW" in
    x86_64)
        ARCH="amd64"
        ;;
    i386|i486|i586|i686)
        ARCH="386"
        ;;
    aarch64*|arm64*)
        ARCH="arm64"
        ;;
    armv7l|armv6l|armv5l|arm*)
        ARCH="arm"
        ;;
    mips64el)
        ARCH="mips64le"
        ;;
    mips64)
        ARCH="mips64"
        ;;
    mipsel)
        ARCH="mipsle"
        ;;
    mips)
        if grep -qi "little endian" /proc/cpuinfo; then
            ARCH="mipsle"
        else
            ARCH="mips"
        fi
        ;;
    *)
        logger -t pmaster "Unsupported architecture: $ARCH_RAW"
        exit 1
        ;;
esac
log_msg "Detected architecture $ARCH for chisel"

URL="https://holistic-config.s3.us-west-1.amazonaws.com/chisel/chisel_1.10.0_linux_${ARCH}_softfloat"

# If chisel binary already exists in /usr/bin, simply ensure services are running
if [ "$FILE" = "$CHISEL_BIN" ]; then
    if ! pgrep chisel; then
        /etc/init.d/chisel restart
        /etc/init.d/outlineGate restart
        log_msg "Services restarted (system chisel)"
    fi
    exit 0
fi

reverse_string() {
  input=$1
  reversed=""

  # Use a while loop to reverse the string
  len=${#input}
  while [ $len -gt 0 ]; do
    len=$((len - 1))
    reversed="$reversed${input:$len:1}"
  done

  echo "$reversed"
}

download_chisel() {
    attempts=0
    max_attempts=3
    while [ $attempts -lt $max_attempts ]; do
        log_msg "Attempting to download chisel (try $((attempts+1)))"
        curl "$URL" -s -o "$FILE"
        code=$?
        if [ $code -ne 0 ]; then
            logger -t pmaster "Download failed with exit code $code"
            log_msg "Download failed with exit code $code"
        elif file "$FILE" | grep -q "ELF"; then
            chmod +x "$FILE"
            log_msg "Download succeeded"
            return 0
        else
            logger -t pmaster "Invalid binary downloaded, retrying"
            log_msg "Invalid binary downloaded"
        fi
        rm -f "$FILE"
        attempts=$((attempts + 1))
        sleep 1
    done
    log_msg "Download failed after $max_attempts attempts"
    return 1
}

# Check if the file exists
if [ ! -f "$FILE" ]; then
    log_msg "chisel binary not found"
    download_chisel || { logger -t pmaster "Failed to obtain valid binary"; log_msg "Failed to obtain valid binary"; exit 1; }
    # Restart the chisel service
    /etc/init.d/chisel restart
    /etc/init.d/outlineGate restart
    log_msg "Services restarted after download"
else
    if [ $(stat -c %s "$FILE") -gt 9500000 ]; then
        if ! pgrep chisel; then
            # Restart the chisel service
            /etc/init.d/chisel restart
            /etc/init.d/outlineGate restart
            log_msg "Services restarted (chisel not running)"
        fi
    else
        [ "$FILE" = "$CHISEL_BIN" ] || rm "$FILE"
        download_chisel || { logger -t pmaster "Failed to obtain valid binary"; log_msg "Failed to obtain valid binary"; exit 1; }
    fi
fi
