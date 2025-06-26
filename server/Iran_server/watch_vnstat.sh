#!/bin/bash
watch -n60 "vnstat -i eth0 --oneline | awk -F';' '{print \$3" "\$4" (rx↔tx)"}'"
