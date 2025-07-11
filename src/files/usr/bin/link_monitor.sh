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
    device=$(ifstatus "$iface" 2>/dev/null | jq -r '.device // .l3_device')
    [ -n "$device" ] && [ "$device" != "null" ] && iface="$device"
    if ping -I "$iface" -c1 -W2 "$host" >/dev/null 2>&1; then
        echo "$(date +"%F %T") [$host] OK" >> "$file"
    else
        echo "$(date +"%F %T") [$host] FAIL" >> "$file"
    fi
    tail -n 1000 "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

check_vpn(){
    status=$(sh /usr/bin/wg_scripts.sh status)
    ks=$(uci get routro.settings.killswitch 2>/dev/null)
    [ -z "$ks" ] && ks="1"
    if echo "$status" | grep '__Connected__' >/dev/null 2>&1; then
        echo "$(date +"%F %T") [vpn] OK" >> "$VPN_LOG"
        [ "$ks" = "1" ] && /usr/bin/vpn_killswitch.sh unblock
    else
        echo "$(date +"%F %T") [vpn] FAIL" >> "$VPN_LOG"
        [ "$ks" = "1" ] && /usr/bin/vpn_killswitch.sh block
    fi
    tail -n 1000 "$VPN_LOG" > "$VPN_LOG.tmp" && mv "$VPN_LOG.tmp" "$VPN_LOG"
}

while true; do
    check_iface "$STARLINK_IF" "$PING_STAR" "$STARLINK_LOG"
    check_iface "$IRAN_IF" "$PING_IR" "$IRAN_LOG"
    check_iface "$CITY_IF" "$PING_IR" "$CITY_LOG"
    check_vpn
    sleep 120
done
