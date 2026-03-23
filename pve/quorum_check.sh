#!/bin/bash
###############################################################################
# Script Name: quorum_check.sh
# Description: Checks QDevice cluster status for Proxmox clusters.
#
# Author: Will Bradshaw (Bullium Consulting) <wbradshaw@bullium.com>
# Version: 1.1
# Date: 2025-07-08
# Support: support@bullium.com
###############################################################################

set -euo pipefail

echo "Checking QDevice Cluster Status..."
sudo corosync-qnetd-tool -s
