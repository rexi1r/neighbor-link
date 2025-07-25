#!/usr/bin/env bash

# This script is designed to run on Ubuntu systems with AMD64 architecture.
# Please ensure you are running this script on a compatible system.

set -e

# Determine the absolute path to this script directory so all other
# paths remain valid even when we change directories later on.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#Openwrt Version
wrt_version="23.05.2"

#Target Device
#              Profile                Arch    Chip
targets=( "tplink_archer-c7-v5    ath79   generic" \
          "tplink_archer-c7-v2    ath79   generic" \
          "tplink_archer-a7-v5    ath79   generic" \
          "glinet_gl-mt300a       ramips  mt7620" \
          "tplink_archer-ax23-v1  ramips  mt7621"
        )

declare -A target_info
for entry in "${targets[@]}"; do
    target_info["$(echo "$entry" | awk '{print $1}')"]="$(echo "$entry" | cut -d' ' -f2-)"
done

# Excluded packages
EXCLUDE_PACKAGES='-dnsmasq -wpad-basic-mbedtls'

# Included Packages
INCLUDE_PACKAGES='curl dnsmasq-full luci luci-base iwinfo wireguard-tools kmod-nft-core kmod-nft-fib kmod-nft-nat kmod-nft-offload mtd ubus ubusd rpcd rpcd-mod-file rpcd-mod-iwinfo uci uhttpd uhttpd-mod-ubus gnupg tinyproxy jq coreutils-stat coreutils-nohup lua luci-lua-runtime luasocket uhttpd-mod-lua coreutils-base64 wpad-openssl pbr kmod-br-netfilter kmod-ipt-physdev iptables-mod-physdev'

FILES="$SCRIPT_DIR/files"

BUILD_DIR="$SCRIPT_DIR/build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Optional directory containing a pre-extracted OpenWrt ImageBuilder. When
# set, the script will reuse this directory instead of downloading a fresh
# archive each time.
IMAGEBUILDER_DIR=${IMAGEBUILDER_DIR:-}

# The new release version should be transfered as a first variable
if [ -n "$1" ]; then
  release_version=$1
else
  release_version="0.0.0"
fi

if [ -n "$2" ]; then
  profiles=$2
else
  profiles="${!target_info[*]}"
fi

for profile in $profiles; do

  IFS=' ' read -r cpu_arch chipset <<< "${target_info[$profile]}"

  PATH_PART="$wrt_version-$cpu_arch-$chipset"

  download_url="https://archive.openwrt.org/releases/$wrt_version/targets/$cpu_arch/$chipset/openwrt-imagebuilder-$PATH_PART.Linux-x86_64.tar.xz"

  if [ -n "$IMAGEBUILDER_DIR" ]; then
    IMAGEBUILDER_REPO="$IMAGEBUILDER_DIR/openwrt-imagebuilder-$PATH_PART.Linux-x86_64"
    if [ ! -d "$IMAGEBUILDER_REPO" ]; then
      echo "ImageBuilder not found at $IMAGEBUILDER_REPO" >&2
      exit 1
    fi
  else
    rm -rf openwrt-imagebuilder-*
    curl -fsSL "$download_url" -O
    tar -J -x -f openwrt-imagebuilder-"$PATH_PART".Linux-x86_64.tar.xz 2>/dev/null > /dev/null
    IMAGEBUILDER_REPO="openwrt-imagebuilder-$PATH_PART.Linux-x86_64"
  fi

  # Build chisel for routers
  CHISEL_VERSION=$(go list -m -f '{{.Version}}' github.com/jpillora/chisel@latest)
  GOOS=linux GOARCH=mipsle GOMIPS=softfloat \
    go install -ldflags="-s -w -X github.com/jpillora/chisel/share.BuildVersion=${CHISEL_VERSION}" \
    github.com/jpillora/chisel@${CHISEL_VERSION}
  mkdir -p "$BUILD_DIR"
  cp "$(go env GOPATH)/bin/linux_mipsle/chisel" "$BUILD_DIR/chisel-linux-mipsle"
  # Bundle chisel into the firmware
  mkdir -p "$FILES/usr/bin"
  cp "$BUILD_DIR/chisel-linux-mipsle" "$FILES/usr/bin/chisel"
  chmod +x "$FILES/usr/bin/chisel"

  sed -i "s/option version .*/option version '$release_version'/" "$FILES/etc/config/routro"
  sed -i "s/option profile .*/option profile '$profile'/" "$FILES/etc/config/routro"
  
    # Check and copy profile-specific network config if it exists
  if [ -f "$FILES/etc/config/network.d/$profile.conf" ]; then
    cp "$FILES/etc/config/network.d/$profile.conf" "$FILES/etc/config/network"
  fi
  
  cd "$IMAGEBUILDER_REPO"

  #Make the images
  make image PROFILE="$profile" PACKAGES="$INCLUDE_PACKAGES $EXCLUDE_PACKAGES" FILES=$FILES

  dest_of_bin="bin/targets/$cpu_arch/$chipset/"

  # Loop over the files with .bin extension in the bin/ directory
  for file in $(find "$dest_of_bin" -type f -name "*.bin"); do

    newname=$(echo "$file" | sed " s|openwrt-$PATH_PART-$profile-|$profile-$release_version-| " )

    newfile="$BUILD_DIR/$(basename "$newname")"
    echo "$newfile:"
    # Rename the file
    mv "$file" "$newfile"

  done

  cd ../

done
