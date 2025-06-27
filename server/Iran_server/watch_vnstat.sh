#!/bin/bash

# Network interface to monitor. Can be overridden by setting the NL_INTERFACE
# environment variable before running this script.
INTERFACE="${NL_INTERFACE:-eth0}"

watch -n60 "vnstat -i $INTERFACE --oneline | awk -F';' '{print \$3 \" \$4 \" (rx↔tx)\"}'"
