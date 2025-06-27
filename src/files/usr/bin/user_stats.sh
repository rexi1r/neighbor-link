#!/bin/sh
# Display per-user traffic statistics based on firewall rules

CHAIN="zone_guest_zone_forward"

# Default to using iptables counters. If the chain doesn't exist, fall back to
# firewall4's nftables implementation.
USE_NFT=0
if ! iptables -L "$CHAIN" >/dev/null 2>&1; then
    nft_chain=$(nft list table inet fw4 2>/dev/null | \
        grep -o "chain zone_guest[^ ]*forward" | head -n1 | awk '{print $2}')
    if [ -n "$nft_chain" ]; then
        CHAIN="$nft_chain"
        USE_NFT=1
    fi
fi

for sec in $(uci show users | grep '=users' | cut -d'.' -f2 | cut -d'=' -f1); do
    macs=$(uci -q get users.$sec.current_macs 2>/dev/null)
    [ -z "$macs" ] && macs=$(uci -q get users.$sec.macs 2>/dev/null)
    total_rx=0
    total_tx=0
    for m in $(echo $macs | tr ',' ' '); do
        if [ $USE_NFT -eq 0 ]; then
            stats=$(iptables -nvx -L "$CHAIN" 2>/dev/null | grep -i "$m" | \
                awk '{rx+=$2; tx+=$1} END {print rx " " tx}')
        else
            stats=$(nft list chain inet fw4 "$CHAIN" 2>/dev/null | grep -i "$m" | \
                awk '{
                        for(i=1;i<=NF;i++){
                            if($i=="bytes") rx+=$(i+1);
                            if($i=="packets") tx+=$(i+1);
                        }
                    } END {print rx " " tx}')
        fi
        rx=$(echo $stats | awk '{print $1}')
        tx=$(echo $stats | awk '{print $2}')
        [ -n "$rx" ] && total_rx=$((total_rx + rx))
        [ -n "$tx" ] && total_tx=$((total_tx + tx))
    done
    echo "$sec $total_rx $total_tx"
done
