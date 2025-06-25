#!/bin/sh

STARLINK_IF="wwan"
IRAN_IF="wan"
CITY_IF="wan2"

link="$1"
host="$2"

case "$link" in
    starlink)
        iface="$STARLINK_IF"
        [ -z "$host" ] && host="8.8.8.8"
        ;;
    iran)
        iface="$IRAN_IF"
        [ -z "$host" ] && host="5.52.0.1"
        ;;
    citylink)
        iface="$CITY_IF"
        [ -z "$host" ] && host="5.52.0.1"
        ;;
    vpn)
        status=$(sh /usr/bin/wg_scripts.sh status)
        echo "$status" | grep '__Connected__' >/dev/null 2>&1 && { echo "OK"; exit 0; }
        echo "FAIL"; exit 0
        ;;
    *)
        echo "UNKNOWN"
        exit 1
        ;;
esac

if ping -I "$iface" -c1 -W2 "$host" >/dev/null 2>&1; then
    echo "OK"
else
    echo "FAIL"
fi
