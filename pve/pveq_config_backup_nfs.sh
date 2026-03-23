#!/bin/bash
###############################################################################
# Script Name: pveq_config_backup_nfs.sh
# Description: Backs up Proxmox QDevice configuration files to NFS share
# Purpose: QDevice-specific configuration backup (excludes /etc/pve)
#
# Author: Will Bradshaw (Bullium Consulting) <wbradshaw@bullium.com>
# Version: 1.1
# Date: 2025-07-08
# Support: support@bullium.com
###############################################################################

set -euo pipefail

# Get the script directory for sourcing shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared backup utilities
source "$SCRIPT_DIR/lib/backup_utils.sh"

# Configuration for QDevice NFS backup
BACKUP_ROOT="/mnt/nfs/backups/pve/pveq-backups"
RETENTION_DAYS=60
COMPRESS_ALGO="zstd"

# QDevice-specific source directories (excludes /etc/pve)
QDEVICE_DIRS=(
    "/etc/systemd"
    "/etc/systemd/system"
    "/etc/fstab"
    "/etc/network/interfaces"
    "/etc/hosts"
    "/etc/resolv.conf"
    "/etc/cron.d"
)

# Validate backup destination
validate_backup_root "$BACKUP_ROOT"

# Initialize backup configuration
init_backup_config "$BACKUP_ROOT" "$RETENTION_DAYS" "$COMPRESS_ALGO"

# Set custom source directories for QDevice
set_source_dirs "${QDEVICE_DIRS[@]}"

# Setup environment and run backup
setup_backup_environment
run_backup