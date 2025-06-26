#!/bin/sh

STARLINK_IF="wwan"
IRAN_IF="wan"
CITY_IF="wan2"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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
        echo "$status" | grep '__Connected__' >/dev/null 2>&1 && {
            printf '%b\n' "${GREEN}OK${NC}"
            exit 0
        }
        printf '%b\n' "${RED}FAIL${NC}"
        exit 0
        ;;
    *)
        echo "UNKNOWN"
        exit 1
        ;;
esac

# Determine the actual network device for the interface
device=$(ifstatus "$iface" 2>/dev/null | jq -r '.device // .l3_device')
[ -n "$device" ] && [ "$device" != "null" ] && iface="$device"

if ping -I "$iface" -c1 -W2 "$host" >/dev/null 2>&1; then
    printf '%b\n' "${GREEN}OK${NC}"
else
    printf '%b\n' "${RED}FAIL${NC}"
fi
