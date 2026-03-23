#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024-2026 Bullium Consulting
###############################################################################
# Script Name: pve_config_backup_nfs.sh
# Description: Backs up critical Proxmox configuration files to NFS share
# Purpose: Network-based disaster recovery configuration backup
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

# Configuration for NFS backup
BACKUP_ROOT="/mnt/nfs/backups/pve/node-backups"
RETENTION_DAYS=60
COMPRESS_ALGO="zstd"

# Validate backup destination
validate_backup_root "$BACKUP_ROOT"

# Initialize backup configuration
init_backup_config "$BACKUP_ROOT" "$RETENTION_DAYS" "$COMPRESS_ALGO"

# Setup environment and run backup
setup_backup_environment
run_backup