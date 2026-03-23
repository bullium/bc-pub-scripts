#!/bin/bash
###############################################################################
# Script Name: pve_status.sh
# Description: Generates a formatted system configuration and service status report for Proxmox VE nodes.
#
# Author: Will Bradshaw (Bullium Consulting) <wbradshaw@bullium.com>
# Version: 1.0
# Date: 2025-07-05
# Support: support@bullium.com
###############################################################################

set -euo pipefail

BOLD='\033[1m'
NORMAL='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'

# Define the quorum node to ping
QDIP="192.168.69.8"
QDNAME="bc-pveq"

# System Information
echo -e "${BOLD}### Proxmox Node Status Report${NORMAL}"
echo "Generated on:$(date '+%Y-%m-%d %H:%M:%S')"
echo
echo -e "${BLUE}### System Overview${NORMAL}"
printf "%-25s: %s\n" "Hostname" "$(hostname)"
printf "%-25s: %s\n" "PVE Version" "$(pveversion -v | grep proxmox-ve)"
printf "%-25s: %s\n" "Uptime" "$(uptime -p)"
printf "%-25s: %s\n" "CPU Load" "$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')"
printf "%-25s: %s\n" "Memory Usage" "$(free -h | awk '/Mem/{print $3"/"$2}')"
printf "%-25s: %s\n" "Disk Usage (Root)" "$(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')"

# Cluster Status
echo -e "\n${BLUE}### Cluster Configuration${NORMAL}"

# Ping the node with 1 packet and check if it responds
ping_status=0
ping -c 1 "$QDIP" > /dev/null 2>&1 || ping_status=$?

echo "Validating Qdevice Status: $QDNAME"

if [ "$ping_status" -eq 0 ]; then
    echo "Quarum node: $QDIP is ONLINE"
else
    echo "Quarum node: $QDIP is OFFLINE"
fi
echo

if [ -f /etc/pve/corosync.conf ]; then
    printf "%-25s: %s\n" "Cluster Status" "$(pvecm status || echo 'N/A')"
else
    echo "Node is not configured in a cluster"
fi

# Service Status
echo -e "\n${BLUE}### Critical Services Status${NORMAL}"
services=("corosync" "pve-cluster" "pvedaemon" "pveproxy" "pvestatd")
for service in "${services[@]}"; do
    status=$(systemctl is-active "$service")
    printf "%-25s: %s\n" "$service" "$status"
done

# Storage Overview
echo -e "\n${BOLD}### Storage Configuration${NORMAL}"

# Disk Usage
echo -e "\n${BLUE}== Filesystem Usage ==${NORMAL}"
df -h | grep -v tmpfs | grep -v udev | grep -v loop

#Storage Pools
echo -e "\n${BLUE}### Storage Pool(s) Status${NORMAL}"
printf "%-15s %-12s %-12s %-12s %-12s\n" "Storage Pool(s)" "" "" "" ""
pvesm status | grep -v STORAGE | while read -r storage type status total used; do
    printf "%-15s %-12s %-12s %-12s %-12s\n" "$storage" "$type" "$status" "${total:-N/A}" "${used:-N/A}"
done

# Physical Disk Information
echo -e "\n${BLUE}### Physical Disks${NORMAL}"
printf "%-15s %-12s %-15s %-12s\n" "DEVICE" "SIZE" "MODEL" "FSTYPE"
lsblk -dno NAME,SIZE,MODEL,FSTYPE | while read -r name size model fstype; do
    printf "%-15s %-12s %-15s %-12s\n" "/dev/$name" "$size" "${model:--}" "${fstype:--}"
done

# Network Configuration
# Initialize counter
not_exist_count=0
declare -a missing_devices=()

echo -e "\n${BLUE}### Network Interfaces${NORMAL}"
for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
    # Check if device exists
    if ip link show "$iface" 2>/dev/null >/dev/null; then
        state=$(ip -br link show "$iface" | awk '{print $2}')
        addr=$(ip -br addr show "$iface" | awk '{print $3}')
        printf "%-15s %-15s %-15s\n" "$iface" "${addr:-No IP}" "$state"
    else
        ((not_exist_count++))
        missing_devices+=("$iface")
    fi
done

# Print summary at the bottom
if [ "$not_exist_count" -gt 0 ]; then
    echo -e "\n${RED}Summary of Missing Devices:${NORMAL}"
    echo "Total devices that do not exist: $not_exist_count"
    echo "Missing devices: ${missing_devices[*]}"
fi
# VM/Container Status
#!/bin/bash
echo
echo -e "${BOLD}### VM and LXC Status Report${NORMAL}"
echo
echo -e "${BLUE}### QEMU Virtual Machines${NORMAL}"
printf "%-6s %-20s %-10s %-10s %-10s %-8s\n" "VMID" "NAME" "STATUS" "MEM(MB)" "DISK(GB)" "PID"
qm list | grep -v VMID | while read -r vmid name status mem disk pid; do
    printf "%-6s %-20s %-10s %-10s %-10s %-8s\n" "$vmid" "$name" "$status" "$mem" "$disk" "$pid"
done

echo
echo -e "${BLUE}### LXC Containers${NORMAL}"
printf "%-6s %-12s %-8s %-20s\n" "VMID" "Status" "Lock" "Name"
pct list | grep -v VMID | while read -r vmid status lock name; do
    printf "%-6s %-12s %-8s %-20s\n" "$vmid" "$status" "${lock:--}" "$name"
done

