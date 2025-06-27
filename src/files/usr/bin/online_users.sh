#!/bin/sh
# Display number of active devices per user based on ARP table

for sec in $(uci show users | grep '=users' | cut -d'.' -f2 | cut -d'=' -f1); do
    max=$(uci -q get users.$sec.max 2>/dev/null)
    macs=$(uci -q get users.$sec.current_macs 2>/dev/null)
    [ -z "$macs" ] && macs=$(uci -q get users.$sec.macs 2>/dev/null)
    active_count=0
    active_list=""
    for m in $(echo $macs | tr ',' ' '); do
        if grep -iq " $m " /proc/net/arp; then
            active_count=$((active_count + 1))
            active_list="$active_list $m"
        fi
    done
    active_list=$(echo $active_list | xargs)
    if [ -n "$max" ]; then
        echo "$sec $active_count/$max $active_list"
    else
        echo "$sec $active_count $active_list"
    fi
done
