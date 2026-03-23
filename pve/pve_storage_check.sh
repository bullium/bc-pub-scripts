#!/bin/bash
###############################################################################
# Script Name: pve_storage_check.sh
# Description: Checks storage status and usage on Proxmox nodes.
#
# Author: Will Bradshaw (Bullium Consulting) <wbradshaw@bullium.com>
# Version: 1.0
# Date: 2025-07-05
# Support: support@bullium.com
###############################################################################

set -euo pipefail

echo 'Storage Repo (datastore) Status'
echo
pvesr status 

# See the LVM Volume Group information
# See the LVM logical volumes
echo 'Storage Volume Groups Status'
echo
vgs 
ls -l /dev/mapper/

# See the ZFS pool information
echo 'Storage ZFS Pool Status'
zpool status 

# See disk details
echo 'Disk Information' 
echo
df -h
