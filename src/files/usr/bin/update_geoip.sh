#!/bin/sh

CIDR_URL="https://www.iwik.org/ipcountry/IR.cidr"
IPV6_URL="https://www.iwik.org/ipcountry/IR.ipv6"
CACHE_DIR="/etc/geoip"
CIDR_FILE="$CACHE_DIR/IR.cidr"
IPV6_FILE="$CACHE_DIR/IR.ipv6"
DEFAULT_FILE="$CACHE_DIR/IR_default.list"
BLOCKLIST_FILE="$CACHE_DIR/blocklist.list"

mkdir -p "$CACHE_DIR"

MODE=$(uci -q get routro.routing.mode 2>/dev/null)

[ -z "$MODE" ] && MODE="default"

dest_addr=""

if [ "$MODE" = "cidr" ]; then
    /usr/bin/curl -fsSL "$CIDR_URL" -o "$CIDR_FILE" && \
    dest_addr=$(grep -v '^#' "$CIDR_FILE" | tr '\n' ' ')
    /usr/bin/curl -fsSL "$IPV6_URL" -o "$IPV6_FILE" >/dev/null 2>&1
elif [ "$MODE" = "default" ]; then
    [ -f "$DEFAULT_FILE" ] && dest_addr=$(cat "$DEFAULT_FILE")
fi

if [ -f "$BLOCKLIST_FILE" ]; then
    block_addr=$(grep -v '^#' "$BLOCKLIST_FILE" | tr '\n' ' ')
    dest_addr="$dest_addr $block_addr"
fi
dest_addr=$(echo "$dest_addr" | xargs)


if [ -n "$dest_addr" ]; then
    uci set pbr.@policy[0].dest_addr="$dest_addr"
    uci set pbr.@policy[0].enabled='1'
else
    uci set pbr.@policy[0].enabled='0'
    uci delete pbr.@policy[0].dest_addr 2>/dev/null
fi
uci commit pbr
/etc/init.d/pbr restart
