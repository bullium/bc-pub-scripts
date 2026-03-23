#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024-2026 Bullium Consulting
# =============================================================================
# File:        tests/bats/pve.bats
# Description: Structural tests for pve/ scripts
# Tests:       file exists, set -euo pipefail, shellcheck
# =============================================================================

load "helpers/common"

setup() {
    cd "$REPO_ROOT"
}

# --- pve_config_backup.sh ---------------------------------------------------

@test "pve_config_backup: file exists" {
    [ -f pve/pve_config_backup.sh ]
}

@test "pve_config_backup: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/pve_config_backup.sh
}

@test "pve_config_backup: passes shellcheck" {
    run shellcheck -S warning pve/pve_config_backup.sh
    [ "$status" -eq 0 ]
}

# --- pve_config_backup_nfs.sh ------------------------------------------------

@test "pve_config_backup_nfs: file exists" {
    [ -f pve/pve_config_backup_nfs.sh ]
}

@test "pve_config_backup_nfs: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/pve_config_backup_nfs.sh
}

@test "pve_config_backup_nfs: passes shellcheck" {
    run shellcheck -S warning pve/pve_config_backup_nfs.sh
    [ "$status" -eq 0 ]
}

# --- pve_config_backup_usb.sh ------------------------------------------------

@test "pve_config_backup_usb: file exists" {
    [ -f pve/pve_config_backup_usb.sh ]
}

@test "pve_config_backup_usb: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/pve_config_backup_usb.sh
}

@test "pve_config_backup_usb: passes shellcheck" {
    run shellcheck -S warning pve/pve_config_backup_usb.sh
    [ "$status" -eq 0 ]
}

# --- pveq_config_backup_nfs.sh -----------------------------------------------

@test "pveq_config_backup_nfs: file exists" {
    [ -f pve/pveq_config_backup_nfs.sh ]
}

@test "pveq_config_backup_nfs: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/pveq_config_backup_nfs.sh
}

@test "pveq_config_backup_nfs: passes shellcheck" {
    run shellcheck -S warning pve/pveq_config_backup_nfs.sh
    [ "$status" -eq 0 ]
}

# --- quorum_check.sh ---------------------------------------------------------

@test "quorum_check: file exists" {
    [ -f pve/quorum_check.sh ]
}

@test "quorum_check: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/quorum_check.sh
}

@test "quorum_check: passes shellcheck" {
    run shellcheck -S warning pve/quorum_check.sh
    [ "$status" -eq 0 ]
}

# --- rpi_version_check.sh ----------------------------------------------------

@test "rpi_version_check: file exists" {
    [ -f pve/rpi_version_check.sh ]
}

@test "rpi_version_check: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/rpi_version_check.sh
}

@test "rpi_version_check: passes shellcheck" {
    run shellcheck -S warning pve/rpi_version_check.sh
    [ "$status" -eq 0 ]
}

# --- ha_tool.sh ---------------------------------------------------------------

@test "ha_tool: file exists" {
    [ -f pve/ha_tool.sh ]
}

@test "ha_tool: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/ha_tool.sh
}

@test "ha_tool: passes shellcheck" {
    run shellcheck -S warning pve/ha_tool.sh
    [ "$status" -eq 0 ]
}

# --- deploy_proxmox_monitoring_stack_v1.sh ------------------------------------

@test "deploy_proxmox_monitoring_stack: file exists" {
    [ -f pve/deploy_proxmox_monitoring_stack_v1.sh ]
}

@test "deploy_proxmox_monitoring_stack: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/deploy_proxmox_monitoring_stack_v1.sh
}

# --- pve_status.sh ------------------------------------------------------------

@test "pve_status: file exists" {
    [ -f pve/pve_status.sh ]
}

@test "pve_status: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/pve_status.sh
}

@test "pve_status: passes shellcheck" {
    run shellcheck -S warning pve/pve_status.sh
    [ "$status" -eq 0 ]
}

# --- pve_storage_check.sh ----------------------------------------------------

@test "pve_storage_check: file exists" {
    [ -f pve/pve_storage_check.sh ]
}

@test "pve_storage_check: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/pve_storage_check.sh
}

@test "pve_storage_check: passes shellcheck" {
    run shellcheck -S warning pve/pve_storage_check.sh
    [ "$status" -eq 0 ]
}

# --- update_ts_cert.sh --------------------------------------------------------

@test "update_ts_cert: file exists" {
    [ -f pve/update_ts_cert.sh ]
}

@test "update_ts_cert: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/update_ts_cert.sh
}

@test "update_ts_cert: passes shellcheck" {
    run shellcheck -S warning pve/update_ts_cert.sh
    [ "$status" -eq 0 ]
}

# --- zfs_replace_drive.sh -----------------------------------------------------

@test "zfs_replace_drive: file exists" {
    [ -f pve/zfs_replace_drive.sh ]
}

@test "zfs_replace_drive: has set -euo pipefail" {
    grep -q 'set -euo pipefail' pve/zfs_replace_drive.sh
}

@test "zfs_replace_drive: passes shellcheck" {
    run shellcheck -S warning pve/zfs_replace_drive.sh
    [ "$status" -eq 0 ]
}

# --- backup_utils.sh (library) -----------------------------------------------

@test "backup_utils (lib): file exists" {
    [ -f pve/lib/backup_utils.sh ]
}

@test "backup_utils (lib): passes shellcheck" {
    run shellcheck -S warning pve/lib/backup_utils.sh
    [ "$status" -eq 0 ]
}
