#!/bin/sh

USERNAME="$1"
PASSWORD="$2"
CLIENT_IP="$3"

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] ; then
    exit 1
fi

validate_mac_address() {
    local mac_address="$1"

    # Use grep to match a valid MAC address format (xx:xx:xx:xx:xx:xx)
    if echo "$mac_address" | grep -Eq "^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$"; then
        return 0  # Valid MAC address
    fi

    return 1  # Invalid MAC address
}


validate_ipv4_address() {
    local ipv4_address="$1"

    # Use a simple regular expression for IPv4 validation
    if echo "$ipv4_address" | grep -Eq "^([0-9]{1,3}\.){3}[0-9]{1,3}$"; then
        # Check if each octet is within the valid range (0-255)
        for octet in $(echo "$ipv4_address" | tr '.' ' '); do
            if [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
                return 1  # Invalid octet
            fi
        done
        return 0  # Valid IPv4 address
    fi

    return 1  # Invalid IPv4 address
}

is_positive_number() {
    local number="$1"

    # Use grep to check for a positive integer (including zero)
    if echo "$number" | grep -Eq "^[0-9]+$"; then
        # Check if the number is greater than or equal to 0
        if [ "$number" -ge 0 ]; then
            return 0  # Number is positive
        fi
    fi

    return 1  # Number is not positive
}



if ! validate_ipv4_address $CLIENT_IP ;then
  echo "not valid IP"
  exit 1;
fi 

CLIENT_MAC=$( grep $CLIENT_IP /proc/net/arp | grep brlan-2 | awk '{print $4}');

if ! validate_mac_address $CLIENT_MAC ;then
  echo "not valid MAC"
  exit 1;
fi

userAuth=$(uci get users.$USERNAME.password)
if [ $? = 0 ] && [ "$PASSWORD" = "$userAuth" ]; then

  whitelist=$(uci -q get users.$USERNAME.macs)
  current_macs=$(uci -q get users.$USERNAME.current_macs)
  max_devices=$(uci -q get users.$USERNAME.max)

  # remove stale MACs that are no longer present in the ARP table
  list=$(echo "$current_macs" | tr ',' ' ')
  cleaned=""
  for m in $list; do
    grep -iq "$m" /proc/net/arp && cleaned="$cleaned $m"
  done
  cleaned=$(echo $cleaned | xargs 2>/dev/null)
  [ "$cleaned" != "$current_macs" ] && uci set users.$USERNAME.current_macs="$cleaned"
  current_macs="$cleaned"

  allowed=0
  if [ -n "$whitelist" ]; then
    for m in $(echo "$whitelist" | tr ',' ' '); do
      [ "$m" = "$CLIENT_MAC" ] && allowed=1
    done
    [ "$allowed" -eq 0 ] && { echo "unauthorized device"; exit 1; }
  else
    list=$(echo "$current_macs" | tr ',' ' ')
    echo " $list " | grep -iq " $CLIENT_MAC " && allowed=1 || allowed=0
    if [ $allowed -eq 0 ]; then
      count=$(echo $list | wc -w)
      if [ -n "$max_devices" ] && [ "$max_devices" -gt 0 ] && [ $count -ge $max_devices ]; then
        echo "max devices reached"
        exit 1
      fi
      list="$list $CLIENT_MAC"
      list=$(echo $list | xargs)
      uci set users.$USERNAME.current_macs="$list"
    fi
  fi

  FW_RULE_ID=$(sh /usr/bin/manage_mac_access.sh check $CLIENT_MAC)
  if ! is_positive_number $FW_RULE_ID ; then
    sh /usr/bin/manage_mac_access.sh add $CLIENT_MAC
  fi

  uci commit users
  echo "_SUCCESS_"
  exit 0
else
  echo "not match user pass"
  exit 1
fi

