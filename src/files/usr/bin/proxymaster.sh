#!/bin/sh
# Define the file name and the URL to download from
FILE="/tmp/chisel"
# TODO : Some arch is not compatible with this
ARCH=$(uname -m)
URL="https://holistic-config.s3.us-west-1.amazonaws.com/chisel/chisel_1.10.0_linux_${ARCH}_softfloat"

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
        curl "$URL" -s -o "$FILE"
        code=$?
        if [ $code -ne 0 ]; then
            logger -t pmaster "Download failed with exit code $code"
        elif file "$FILE" | grep -q "ELF"; then
            chmod +x "$FILE"
            return 0
        else
            logger -t pmaster "Invalid binary downloaded, retrying"
        fi
        rm -f "$FILE"
        attempts=$((attempts + 1))
        sleep 1
    done
    return 1
}

# Check if the file exists
if [ ! -f "$FILE" ]; then
    download_chisel || { logger -t pmaster "Failed to obtain valid binary"; exit 1; }
    # Restart the chisel service
    /etc/init.d/chisel restart
    /etc/init.d/outlineGate restart
else
    if [ $(stat -c %s /tmp/chisel) -gt 9500000 ]; then
        if ! pgrep chisel; then
            # Restart the chisel service
            /etc/init.d/chisel restart
            /etc/init.d/outlineGate restart
        fi
    else
        rm /tmp/chisel
        download_chisel || { logger -t pmaster "Failed to obtain valid binary"; exit 1; }
    fi
fi
