#!/bin/bash
###############################################################################
# Script Name: update_ts_cert.sh
# Description: Updates and rotates the Tailscale TLS certificate on a
#              Proxmox VE node by fetching the current cert via the Tailscale
#              CLI and applying it to the PVE web interface.
#
# Author: Will Bradshaw (Bullium Consulting) <wbradshaw@bullium.com>
# Version: 1.0
# Support: support@bullium.com
###############################################################################

set -euo pipefail

NAME="$(tailscale status --json | jq '.Self.DNSName | .[:-1]' -r)"
tailscale cert "${NAME}"
pvenode cert set "${NAME}.crt" "${NAME}.key" --force --restart
