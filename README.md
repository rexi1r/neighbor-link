# NeighborLink

## [Installation Guide](https://github.com/nasnet-community/solutions/tree/main/neighbor-link)

نیبرلینک سیستمی است که به افرادی که در شعاع پوشش یک دستگاه استارلینک و اکستندرهای آن قرار دارند، اجازه می‌دهد حتی در شرایطی که اینترنت داخلی و بین‌المللی یک کشور به‌طور کامل قطع شده است، به اینترنت امن و پرسرعت دسترسی پیدا کنند.

نیبرلینک یک سیستم‌عامل OpenWRT شخصی‌سازی‌شده است که به مدیر سیستم امکان می‌دهد اینترنت استارلینک را با کاربران دیگر، مثلاً همسایه‌ها، به اشتراک بگذارد. این سیستم در حال حاضر امکاناتی مانند مدیریت کاربران، تفکیک مسیر (Split Tunneling) و مخفی‌سازی آی‌پی با استفاده از وی‌پی‌ان را فراهم می‌کند. در آینده، قابلیت‌های دیگری مانند لیست سفید (Whitelisting)، لیست سیاه (Blacklisting) و مدیریت ترافیک به نیبرلینک افزوده خواهد شد.

سیتی لینک (CityLink) یکی از گزینه‌های نیبرلینک است که با استفاده از آن می‌توان از راه دور و با استفاده از اینترنت داخلی یک کشور، به‌صورت امن و ناشناس به استارلینک متصل شد. در حال حاضر، می‌توان با پروکسی‌هایی مانند  FoxyProxy و Potasto و همچنین با استفاده از Outline، از سیتی لینک استفاده کرد.

NeighborLink enables individuals in close proximity to a Starlink terminal to retain secure internet access, demonstrating its effectiveness in circumventing widespread internet restrictions.
The core advantage of NeighborLink is providing resilient local internet access, designed to be impervious to nationwide shutdowns.

In scenarios where the government enforces a complete internet blackout, this system ensures that individuals with local access, for example, residents within a building, maintain uninterrupted internet connectivity. This is done by bypassing the Starlink’s proprietary router to use a generic off-the-shelf router and install customized OpenWRT OS on the router to share the Starlink’s internet bandwidth.

Key developments including a user management dashboard, split tunneling and VPN technology have been implemented, with future enhancements planned for whitelisting, blacklisting, and traffic management.

CityLink is a feature to enable remote use of Starlink via the domestic internet. In essence, CityLink is composed of two separate methods:
Proxy (such as FoxyProxy and Potatso)
Outline.
Both the administrator and users can utilize either or both methods according to their needs.
The CityLink solution was designed with an understanding of, and in response to, the dual structure of Iran's internet - differences in domestic and international internet censorship.

The solution includes integrating a cloud server, empowering users to create personal servers, and implementing firewalls to conceal satellite connections. An assessment of Iranian internet providers favored fiber internet and point-to-point connections for their performance and security.

## Building Firmware with Chisel
The `src/build.bash` script fetches the OpenWrt SDK and now also compiles the
[Chisel](https://github.com/jpillora/chisel) tunnel. After extracting the image
builder, run:

> **Note**: To resolve build errors, update your Go toolchain to at least **v1.20**.
Recent versions like **1.22** or **1.24** work as well. After upgrading Go,
rerun the build script and the Chisel compilation step will succeed.

```
CHISEL_VERSION=$(go list -m -f '{{.Version}}' github.com/jpillora/chisel@latest)
GOOS=linux GOARCH=mipsle GOMIPS=softfloat \
  go install -ldflags="-s -w -X github.com/jpillora/chisel/share.BuildVersion=${CHISEL_VERSION}" \
  github.com/jpillora/chisel@${CHISEL_VERSION}
cp $(go env GOPATH)/bin/linux_mipsle/chisel build/chisel-linux-mipsle
```

The compiled binary is stored in `src/build/chisel-linux-mipsle` alongside the
generated firmware images and is now bundled into the firmware at
`/usr/bin/chisel` with executable permissions already set.

Once installed, restart the Chisel-related services so they pick up the binary
location:

```
ssh root@<router-ip> "/etc/init.d/chisel restart && /etc/init.d/outlineGate restart"
```

To build the firmware images themselves, run the build script with a
version label and the desired router profile:

```
cd src
./build.bash <VERSION> <PROFILE>
```

All generated `.bin` files are written to `src/build/`. This directory is
ignored by Git so the firmware artifacts are produced during each build
instead of being stored in the repository.

## User Management Enhancements
Users can limit the number of devices per account using the **Max Devices** field and optionally set a comma separated list of permitted MAC addresses. A helper script `user_stats.sh` prints traffic usage per user based on firewall counters. Stale MAC entries are purged whenever a login occurs so the limit only counts active devices.
The management page table now lists these values beside each username so administrators can quickly review configured limits.
Another helper script `online_users.sh` reports how many devices are currently connected for each user by checking the router's ARP table. The dashboard displays this "Online" count next to the configured maximum.

## Monitoring Panel and Dummy Traffic
A simple monitoring panel shows VNStat bandwidth statistics, including a TX/RX ratio updated every minute by `update_panel.sh`. By default both `update_panel.sh` and the helper script `watch_vnstat.sh` monitor the `eth0` interface, but you can override this by setting the `NL_INTERFACE` environment variable so the TX/RX ratio reflects the correct device. To help keep the ratio reasonable, the helper script `uploader_filler.sh` may upload random data to [transfer.sh](https://transfer.sh) when received traffic greatly exceeds transmitted traffic.
`uploader_filler.sh` now stores the previous receive and transmit counters in `/var/tmp/uploader_filler_state`. If this file is missing, the current counters are recorded and the script exits without uploading. On subsequent runs it compares the difference in RX and TX bytes since the last invocation and only performs an upload when 80% of the received bytes is still greater than the transmitted bytes. The current counters are always written back to the state file so the next run can determine the delta. The script also respects `NL_INTERFACE` so you can monitor any interface.

## License

NeighborLink is released under the [MIT License](LICENSE).
