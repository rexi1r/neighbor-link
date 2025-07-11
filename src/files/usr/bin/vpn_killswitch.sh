#!/bin/sh

IFACE="wwan"

add_rule() {
    iptables -C FORWARD -o "$IFACE" -j DROP 2>/dev/null || iptables -I FORWARD -o "$IFACE" -j DROP
    iptables -C OUTPUT -o "$IFACE" -j DROP 2>/dev/null || iptables -I OUTPUT -o "$IFACE" -j DROP
}

remove_rule() {
    while iptables -C FORWARD -o "$IFACE" -j DROP 2>/dev/null; do
        iptables -D FORWARD -o "$IFACE" -j DROP
    done
    while iptables -C OUTPUT -o "$IFACE" -j DROP 2>/dev/null; do
        iptables -D OUTPUT -o "$IFACE" -j DROP
    done
}

case "$1" in
    block)
        add_rule
        ;;
    unblock)
        remove_rule
        ;;
    *)
        echo "Usage: $0 block|unblock"
        exit 1
        ;;
 esac
