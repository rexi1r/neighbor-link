#!/bin/sh

CIDR_URL="https://www.iwik.org/ipcountry/IR.cidr"
IPV6_URL="https://www.iwik.org/ipcountry/IR.ipv6"
CACHE_DIR="/etc/geoip"
CIDR_FILE="$CACHE_DIR/IR.cidr"
IPV6_FILE="$CACHE_DIR/IR.ipv6"
DEFAULT_FILE="$CACHE_DIR/IR_default.list"

mkdir -p "$CACHE_DIR"

MODE=$(uci -q get routro.routing.mode 2>/dev/null)

[ -z "$MODE" ] && MODE="default"

if [ "$MODE" = "off" ]; then
    uci set pbr.@policy[0].enabled='0'
    uci delete pbr.@policy[0].dest_addr 2>/dev/null
    uci commit pbr
    /etc/init.d/pbr restart
    exit 0
fi

if [ "$MODE" = "cidr" ]; then
    /usr/bin/curl -fsSL "$CIDR_URL" -o "$CIDR_FILE" && \
    dest_addr=$(grep -v '^#' "$CIDR_FILE" | tr '\n' ' ')
    /usr/bin/curl -fsSL "$IPV6_URL" -o "$IPV6_FILE" >/dev/null 2>&1
else
    [ -f "$DEFAULT_FILE" ] && dest_addr=$(cat "$DEFAULT_FILE")
fi

if [ -n "$dest_addr" ]; then
    uci set pbr.@policy[0].dest_addr="$dest_addr"
    uci set pbr.@policy[0].enabled='1'
    uci commit pbr
    /etc/init.d/pbr restart
fi
