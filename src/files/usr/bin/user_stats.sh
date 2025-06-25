#!/bin/sh
# Display per-user traffic statistics based on firewall rules

CHAIN="zone_guest_zone_forward"

for sec in $(uci show users | grep '=users' | cut -d'.' -f2 | cut -d'=' -f1); do
    macs=$(uci -q get users.$sec.current_macs 2>/dev/null)
    [ -z "$macs" ] && macs=$(uci -q get users.$sec.macs 2>/dev/null)
    total_rx=0
    total_tx=0
    for m in $(echo $macs | tr ',' ' '); do
        stats=$(iptables -nvx -L $CHAIN 2>/dev/null | grep $m | awk '{rx+=$2; tx+=$1} END {print rx " " tx}')
        rx=$(echo $stats | awk '{print $1}')
        tx=$(echo $stats | awk '{print $2}')
        [ -n "$rx" ] && total_rx=$((total_rx + rx))
        [ -n "$tx" ] && total_tx=$((total_tx + tx))
    done
    echo "$sec $total_rx $total_tx"
done
