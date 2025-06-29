#!/bin/sh
# this script will work as a api gateway
PROCESS_LOG="/var/log/chisel_process.log"

init_process_log() {
    [ -f "$PROCESS_LOG" ] || { touch "$PROCESS_LOG" && chmod 600 "$PROCESS_LOG"; }
    if [ $(stat -c%s "$PROCESS_LOG" 2>/dev/null || echo 0) -gt 1000000 ]; then
        mv "$PROCESS_LOG" "$PROCESS_LOG.1" 2>/dev/null
        touch "$PROCESS_LOG" && chmod 600 "$PROCESS_LOG"
    fi
}

log_msg() {
    init_process_log
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$PROCESS_LOG"
}

log_msg "dragon.sh called with $*"
response() {
    echo "<___RESPONSE___>"
    echo -e "$1"
    echo "<___END___>"
    exit 0
}

if [ "$1" == "iwscan" ];then
    RESULT=""
    RESULT0=$(iwinfo radio0 scan)
    RESULT1=$(iwinfo radio1 scan)
    if echo "$RESULT0" | grep -q "Band"; then
        RESULT="${RESULT}\n${RESULT0}"
    fi
    if echo "$RESULT1" | grep -q "Band"; then
        RESULT="${RESULT}\n${RESULT1}"
    fi

    response "$RESULT"

fi

# Set the Wifi Client Info
if [ "$1" == "iwset" ];then
    ssid=$( echo "$2" | base64 -d )
    pass=$( echo "$3" | base64 -d )
    band=$4
    encr=$5
    if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
        response "Missing Info"
        exit 1
    fi
    rm -f /tmp/wlansta_2g.value
    rm -f /tmp/wlansta_5g.value
    if [ $band == "2" ];then
        uci set wireless.client_2g.ssid="$ssid"
        uci set wireless.client_2g.key="$pass"
        uci set wireless.client_2g.encryption="$encr"
        uci set wireless.client_2g.disabled="0"
        uci set wireless.client_5g.disabled="1"
        uci commit wireless
        nohup sh -c 'sleep 1 && /etc/init.d/network reload' >/dev/null 2>&1 &
    elif [ $band == "5" ];then
        uci set wireless.client_5g.ssid="$ssid"
        uci set wireless.client_5g.key="$pass"
        uci set wireless.client_5g.encryption="$encr"
        uci set wireless.client_5g.disabled="0"
        uci set wireless.client_2g.disabled="1"
        uci commit wireless
        nohup sh -c 'sleep 1 && /etc/init.d/network reload' >/dev/null 2>&1 & 
    else
        response "Wrong Band"
        exit 1
    fi 
    response "Done"
    exit 0
fi

# Return the Wifi Status
if [ "$1" == "iwstat" ];then
    band=$2
    if [ -z "$2" ]; then
        response "Missing Info"
        exit 1;
    fi

      
    if [ $band == "2" ];then
        # Check if the WiFi STA interface is enabled
        wifi_status=$(uci get wireless.client_2g.disabled)
        IP=$(ifconfig wlansta_2g | grep 'inet addr' | awk -F: '{print $2}' | awk '{print $1}')
    elif [ $band == "5" ];then
        wifi_status=$(uci get wireless.client_5g.disabled)
        IP=$(ifconfig wlansta_5g | grep 'inet addr' | awk -F: '{print $2}' | awk '{print $1}')
    else
        response "Wrong Band"
    fi 
    
    if [ "$wifi_status" = "1" ]; then
        response "Disabled"
    fi
    if [ -z "$IP" ]; then
        response "Connecting..."
        exit 0
    fi

    response "Connected"
fi

if [ "$1" == "ifconfig" ];then
    RESULT=""
    RESULT0=$(ifconfig br-lan)
    RESULT1=$(iwinfo radio1 scan)
    if echo "$RESULT0" | grep -q "Band"; then
        RESULT="${RESULT}\n${RESULT0}"
    fi
    if echo "$RESULT1" | grep -q "Band"; then
        RESULT="${RESULT}\n${RESULT1}"
    fi

    response "$RESULT"

fi

if [ "$1" == "ip-api" ];then
    log_msg "Executing ip-api"
    RESULT=$(curl -s ip-api.com/json?fields=status,message,country,isp,query)
    response "$RESULT"
fi

if [ "$1" == "vpn-on" ];then
    log_msg "Enabling VPN"
    RESULT=$(sh /usr/bin/wg_scripts.sh on)
    response "$RESULT"
fi

if [ "$1" == "vpn-off" ];then
    log_msg "Disabling VPN"
    RESULT=$(sh /usr/bin/wg_scripts.sh off)
    response "$RESULT"
fi

if [ "$1" == "guest-on" ];then
    log_msg "Enabling guest wifi"
    uci set wireless.guest_2g.disabled="0"
    uci set wireless.guest_5g.disabled="0"
    uci commit wireless
    nohup sh -c 'sleep 1 && /etc/init.d/network reload' >/dev/null 2>&1 &

    response "Done"
fi

if [ "$1" == "guest-off" ];then

    log_msg "Disabling guest wifi"

    uci set wireless.guest_2g.disabled="1"
    uci set wireless.guest_5g.disabled="1"
    uci commit wireless
    nohup sh -c 'sleep 1 && /etc/init.d/network reload' >/dev/null 2>&1 &

    response "Done"
fi

if [ "$1" == "guest-set" ];then
    log_msg "Setting guest wifi"
    ssid=$2
    pass=$3
    if [ -z "$1" ] || [ -z "$2" ] ; then
        response "Missing Info"
        exit 1
    fi
    uci set wireless.guest_2g.ssid="$2-2g"
    uci set wireless.guest_2g.key="$3"
    uci set wireless.guest_5g.ssid="$2-5g"
    uci set wireless.guest_5g.key="$3"
    uci commit wireless
    nohup sh -c 'sleep 1 && /etc/init.d/network reload' >/dev/null 2>&1 &
    sleep 4
    response "Done"
fi

if [ "$1" == "wifi-set" ];then
    ssid=$2
    pass=$3
    if [ -z "$1" ] || [ -z "$2" ] ; then
        response "Missing Info"
        exit 1
    fi
    uci set wireless.default_radio1.ssid="$2-2g"
    uci set wireless.default_radio1.key="$3"
    uci set wireless.default_radio0.ssid="$2-5g"
    uci set wireless.default_radio0.key="$3"
    uci commit wireless
    nohup sh -c 'sleep 1 && /etc/init.d/network reload' >/dev/null 2>&1 &
    sleep 4
    response "Done"
fi

if [ "$1" == "infinite-reach-connect" ];then
    log_msg "Infinite Reach connect"

    if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ] || [ -z "$7" ] || [ -z "$8" ] || [ -z "$9" ]; then
        response "Missing_Info"
        exit 1
    fi
    uci set routro.ireach.enabled='1'
    uci set routro.ireach.host=$2
    uci set routro.ireach.port=$3
    uci set routro.ireach.proxyport=$4
    uci set routro.ireach.outlineport=$5
    uci set routro.ireach.proxyfaceport=$6
    uci set routro.ireach.hosttype=$7
    uci set routro.ireach.user=$8
    uci set routro.ireach.pass=$9
    uci commit routro
    uci set tinyproxy.@tinyproxy[0].enabled="1"
    uci set tinyproxy.@tinyproxy[0].BasicAuth="$8 $9"
    uci commit tinyproxy

    # ToDo: uci set mwan3.chisel_server.dest_ip=$3
    /etc/init.d/chisel enable
    /etc/init.d/tinyproxy enable
    /etc/init.d/chisel restart
    /etc/init.d/tinyproxy restart

    # Wait for chisel to establish the connection
    CHISEL_STATUS=""
    for _i in $(seq 1 30); do
        CHISEL_STATUS=$(sh /usr/bin/check_chisel.sh)
        [ "$CHISEL_STATUS" = "Connected" ] && break
        sleep 1
    done

    STATUS=$(/etc/init.d/chisel status)
    [ -z "$STATUS" ] && STATUS="null"

    response "$STATUS $CHISEL_STATUS 2"
fi

if [ "$1" == "infinite-reach-disconnect" ];then
    log_msg "Infinite Reach disconnect"

    uci set routro.ireach.enabled='0'
    uci commit routro
    uci set tinyproxy.@tinyproxy[0].enabled='0'
    uci commit tinyproxy

    /etc/init.d/chisel restart
    /etc/init.d/tinyproxy restart

    sleep 2
    
    STATUS=$(/etc/init.d/chisel status)
    if [ -z "$STATUS" ] ; then
        STATUS="null"
    fi
        
    CHISEL_STATUS=$(sh  /usr/bin/check_chisel.sh)
    
    response "$STATUS $CHISEL_STATUS 2"
fi

if [ "$1" == "infinite-reach-status" ];then
    log_msg "Infinite Reach status"
    iReach_HOST=$(uci get routro.ireach.host)
    iREACH_EN=$(uci get routro.ireach.enabled)
    tPROXY_EN=$(uci get tinyproxy.@tinyproxy[0].enabled)
    sleep 2
    STATUS=$(/etc/init.d/chisel status)
    if [ -z "$STATUS" ] ; then
        STATUS="null"
    fi
        
    CHISEL_STATUS=$(sh  /usr/bin/check_chisel.sh)
    
    response "$iREACH_EN $tPROXY_EN $STATUS $CHISEL_STATUS $iReach_HOST 2"
fi

if [ "$1" == "ireach-proxy-get" ];then
    STATUS=$(/etc/init.d/tinyproxy status)
    USERNAME=$(uci get routro.ireach.user)
    PASSWORD=$(uci get routro.ireach.pass)

    HOST=$(uci get routro.ireach.host)
    PORT=$(uci get routro.ireach.proxyfaceport)
    HOST_TYPE=$(uci get routro.ireach.hosttype)
    sleep 2
    response "$STATUS $HOST_TYPE $USERNAME $PASSWORD $HOST $PORT"
fi

if [ "$1" == "ireach-enable" ];then
    log_msg "ireach enable"
    /etc/init.d/tinyproxy start
    /etc/init.d/tinyproxy enable
    sleep 2
    response "Done"
fi

if [ "$1" == "ireach-disable" ];then
    log_msg "ireach disable"
    /etc/init.d/tinyproxy stop
    /etc/init.d/tinyproxy disable
    sleep 2
    response "Done"
fi

if [ "$1" == "ireach-regen" ];then
    log_msg "ireach regen"
    /etc/init.d/tinyproxy stop
    RANDOMPASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10)
    USER=iReach$(hexdump -n 2 -e '/2 "%u"' /dev/urandom)
    uci set tinyproxy.@tinyproxy[0].BasicAuth="$USER $RANDOMPASS"
    uci commit tinyproxy
    /etc/init.d/tinyproxy start
    sleep 2
    response "Done"
fi

if [ "$1" == "ireach-outline-get" ];then
    log_msg "outline get"
    STATUS=$(/etc/init.d/outlineGate status)
    if [ -z "$STATUS" ] ; then
        STATUS="null"
    fi

    SERVICE_STATUS=$(sh /usr/bin/check_chisel.sh outline)
    key=$(uci get routro.outlinegate.savedKey)
    sleep 2
    response "$STATUS $SERVICE_STATUS $key 4"
fi

if [ "$1" == "ireach-outline-set" ];then
    log_msg "outline set"
    host=$2
    port=$3
    if [ -z "$1" ] || [ -z "$2" ] ; then
        response "Missing_Info"
        exit 1
    fi
    uci set routro.outlinegate.originport="$port"
    uci set routro.outlinegate.originhost="$host"
    uci commit routro

    /etc/init.d/outlineGate enable
    /etc/init.d/outlineGate restart
    sleep 2

    STATUS=$(/etc/init.d/outlineGate status)
    if [ -z "$STATUS" ] ; then
        STATUS="null"
    fi
        
    SERVICE_STATUS=$(sh /usr/bin/check_chisel.sh outline)
    iReach_HOST=$(uci get routro.ireach.host)
    iReach_PORT=$(uci get routro.ireach.outlineport)

    
    response "$STATUS $SERVICE_STATUS $iReach_HOST $iReach_PORT 3"
fi

if [ "$1" == "ireach-outline-write" ];then
    log_msg "outline write"
    uci set routro.outlinegate.savedKey="$2"
    uci commit routro
    response "Done"
fi

if [ "$1" == "wireguard-set-conf" ];then
    log_msg "wireguard set conf"
    config_base64=$2
    echo "$config_base64" | base64 -d > /peer.json
    response "Done"
fi

if [ "$1" = "monitor-log" ]; then
    log_msg "monitor log $2"
    case "$2" in
        starlink) file="/var/log/starlink.log" ;;
        iran) file="/var/log/iran.log" ;;
        vpn) file="/var/log/vpn.log" ;;
        citylink) file="/var/log/citylink.log" ;;
        *) file="/var/log/link-monitor.log" ;;
    esac
    if [ -f "$file" ]; then
        response "$(tail -n 50 $file)"
    else
        response "No log"
    fi
fi

if [ "$1" = "user-stats" ]; then
    log_msg "user stats"
    stats=$(sh /usr/bin/user_stats.sh)
    response "$stats"
fi

if [ "$1" = "user-online" ]; then
    log_msg "user online"
    online=$(sh /usr/bin/online_users.sh)
    response "$online"
fi

if [ "$1" == "check-link" ];then
    log_msg "check link"
    result=$(sh /usr/bin/check_link.sh "$2" "$3")
    response "$result"
fi
