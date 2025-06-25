#!/bin/sh

STARLINK_IF="wwan"
IRAN_IF="wan"
CITY_IF="wan2"
LOG_DIR="/var/log"
STARLINK_LOG="$LOG_DIR/starlink.log"
IRAN_LOG="$LOG_DIR/iran.log"
VPN_LOG="$LOG_DIR/vpn.log"
CITY_LOG="$LOG_DIR/citylink.log"

PING_STAR="8.8.8.8"
PING_IR="5.52.0.1"

check_iface(){
    iface=$1
    host=$2
    file=$3
    if ping -I "$iface" -c1 -W2 "$host" >/dev/null 2>&1; then
        echo "$(date +"%F %T") OK" >> "$file"
    else
        echo "$(date +"%F %T") FAIL" >> "$file"
    fi
}

check_vpn(){
    status=$(sh /usr/bin/wg_scripts.sh status)
    echo "$status" | grep '__Connected__' >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "$(date +"%F %T") OK" >> "$VPN_LOG"
    else
        echo "$(date +"%F %T") FAIL" >> "$VPN_LOG"
    fi
}

while true; do
    check_iface "$STARLINK_IF" "$PING_STAR" "$STARLINK_LOG"
    check_iface "$IRAN_IF" "$PING_IR" "$IRAN_LOG"
    check_iface "$CITY_IF" "$PING_IR" "$CITY_LOG"
    check_vpn
    sleep 120
done
