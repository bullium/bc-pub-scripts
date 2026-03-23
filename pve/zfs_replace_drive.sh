#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024-2026 Bullium Consulting
#
# zfs-replace-drive.sh — Automated ZFS mirror drive replacement for Proxmox
#
# Usage: zfs-replace-drive.sh <pool> <new-drive-id>
#
# Example:
#   zfs-replace-drive.sh rpool ata-Samsung_SSD_870_EVO_500GB_S6PXNL0Y102924K
#
# This script automates the procedure for replacing a failed drive in a ZFS
# mirror on a Proxmox/Debian system with systemd-boot. It:
#   1. Identifies the failed and healthy drives in the pool
#   2. Verifies the replacement drive's partition layout matches
#   3. Initiates zpool replace and monitors resilver
#   4. Syncs the EFI partition and updates boot entries
#   5. Cleans up and reports final status
#
# Author: Will Bradshaw (Bullium Consulting) <wbradshaw@bullium.com>
# Version: 1.1
# Date: 2026-02-08
# Support: support@bullium.com
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }
ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }

usage() {
    echo "Usage: $0 <pool> <new-drive-id>"
    echo ""
    echo "  <pool>          ZFS pool name (e.g. rpool)"
    echo "  <new-drive-id>  by-id name of the new drive, WITHOUT partition suffix"
    echo "                  (e.g. ata-Samsung_SSD_870_EVO_500GB_S6PXNL0Y102924K)"
    echo ""
    echo "The script expects:"
    echo "  - A ZFS mirror pool in DEGRADED state with exactly one UNAVAIL device"
    echo "  - The replacement drive already installed and partitioned to match"
    echo "  - systemd-boot as the EFI bootloader"
    exit 1
}

confirm() {
    local prompt="$1"
    read -rp "$(echo -e "${YELLOW}${prompt} [y/N]:${NC} ")" answer
    [[ "$answer" =~ ^[Yy]$ ]] || { log "Aborted by user."; exit 0; }
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
[[ $EUID -eq 0 ]] || { err "This script must be run as root."; exit 1; }
[[ $# -eq 2 ]] || usage

POOL="$1"
NEW_DRIVE_ID="$2"
NEW_DRIVE_PATH="/dev/disk/by-id/${NEW_DRIVE_ID}"

# ---------------------------------------------------------------------------
# Step 0: Validate inputs
# ---------------------------------------------------------------------------
log "Validating inputs..."

if ! zpool list "$POOL" &>/dev/null; then
    err "Pool '$POOL' does not exist."
    exit 1
fi

if [[ ! -b "$NEW_DRIVE_PATH" ]]; then
    err "Drive not found: $NEW_DRIVE_PATH"
    exit 1
fi

POOL_STATE=$(zpool get -H -o value health "$POOL")
if [[ "$POOL_STATE" != "DEGRADED" ]]; then
    err "Pool '$POOL' is $POOL_STATE, not DEGRADED. Nothing to replace."
    exit 1
fi

ok "Pool '$POOL' is DEGRADED — proceeding with replacement."

# ---------------------------------------------------------------------------
# Step 1: Identify failed and healthy drives
# ---------------------------------------------------------------------------
log "Identifying failed and healthy devices in '$POOL'..."

ZPOOL_STATUS=$(zpool status "$POOL")

# Get the UNAVAIL device (either a numeric ID or a by-id path)
FAILED_DEV=$(echo "$ZPOOL_STATUS" | awk '/UNAVAIL/ {print $1}' | head -1)
if [[ -z "$FAILED_DEV" ]]; then
    err "Could not find an UNAVAIL device in pool '$POOL'."
    exit 1
fi

# Get the old drive name from the "was" annotation if present
OLD_DRIVE_NAME=$(echo "$ZPOOL_STATUS" | grep "UNAVAIL" | grep -oP 'was \K/dev/disk/by-id/[^ ]+' | head -1 || true)

# Get the healthy ONLINE drive in the mirror (by-id path, with partition suffix)
HEALTHY_DEV=$(echo "$ZPOOL_STATUS" | awk '/ONLINE/ && /ata-|nvme-|scsi-/ {print $1}' | head -1)
if [[ -z "$HEALTHY_DEV" ]]; then
    err "Could not find a healthy ONLINE device in the mirror."
    exit 1
fi

# Extract base drive name (strip partition suffix like -part3)
HEALTHY_BASE="${HEALTHY_DEV%%-part[0-9]*}"

# Determine the ZFS partition number from the healthy drive
ZFS_PART_NUM=$(echo "$HEALTHY_DEV" | grep -oP 'part\K[0-9]+$')
if [[ -z "$ZFS_PART_NUM" ]]; then
    err "Could not determine ZFS partition number from '$HEALTHY_DEV'."
    exit 1
fi

echo ""
echo "  Failed device:      $FAILED_DEV"
[[ -n "$OLD_DRIVE_NAME" ]] && echo "  Old drive was:      $OLD_DRIVE_NAME"
echo "  Healthy device:     $HEALTHY_DEV (base: $HEALTHY_BASE)"
echo "  New drive:          $NEW_DRIVE_ID"
echo "  ZFS partition:      part${ZFS_PART_NUM}"
echo ""

# ---------------------------------------------------------------------------
# Step 2: Verify partition layout
# ---------------------------------------------------------------------------
log "Comparing partition layouts..."

HEALTHY_DISK="/dev/disk/by-id/${HEALTHY_BASE}"
LAYOUT_HEALTHY=$(sgdisk -p "$HEALTHY_DISK" 2>/dev/null | awk '/^ *[0-9]/')
LAYOUT_NEW=$(sgdisk -p "$NEW_DRIVE_PATH" 2>/dev/null | awk '/^ *[0-9]/')

if [[ "$LAYOUT_HEALTHY" != "$LAYOUT_NEW" ]]; then
    err "Partition layouts do NOT match!"
    echo ""
    echo "Healthy drive ($HEALTHY_BASE):"
    echo "$LAYOUT_HEALTHY"
    echo ""
    echo "New drive ($NEW_DRIVE_ID):"
    echo "$LAYOUT_NEW"
    echo ""
    err "Partition the new drive to match before retrying."
    exit 1
fi

ok "Partition layouts match."

# ---------------------------------------------------------------------------
# Step 3: ZFS replace
# ---------------------------------------------------------------------------
NEW_ZFS_PART="${NEW_DRIVE_PATH}-part${ZFS_PART_NUM}"
if [[ ! -b "$NEW_ZFS_PART" ]]; then
    err "ZFS partition not found: $NEW_ZFS_PART"
    exit 1
fi

echo ""
confirm "Replace '$FAILED_DEV' with '${NEW_DRIVE_ID}-part${ZFS_PART_NUM}' in pool '$POOL'?"

log "Running zpool replace..."
zpool replace "$POOL" "$FAILED_DEV" "$NEW_ZFS_PART"
ok "zpool replace issued."

# ---------------------------------------------------------------------------
# Step 4: Monitor resilver
# ---------------------------------------------------------------------------
log "Monitoring resilver progress (Ctrl+C to stop monitoring — resilver continues in background)..."
echo ""

while true; do
    STATUS=$(zpool status "$POOL")
    if echo "$STATUS" | grep -q "resilver in progress"; then
        PROGRESS=$(echo "$STATUS" | grep -E "^\s+scan:" -A1 | tail -1 | sed 's/^\s*//')
        echo -ne "\r  ${CYAN}${PROGRESS}${NC}          "
        sleep 5
    elif echo "$STATUS" | grep -q "resilvered"; then
        echo ""
        RESILVER_LINE=$(echo "$STATUS" | grep "resilvered")
        ok "Resilver complete: $RESILVER_LINE"
        break
    else
        echo ""
        warn "Unexpected pool state. Check 'zpool status $POOL'."
        break
    fi
done

# ---------------------------------------------------------------------------
# Step 5: Sync EFI partition and update boot entries
# ---------------------------------------------------------------------------

# Determine EFI partition number — look for an EF00 partition
EFI_PART_NUM=$(sgdisk -p "$HEALTHY_DISK" 2>/dev/null | awk '$6 == "EF00" {print $1}' | head -1)

if [[ -z "$EFI_PART_NUM" ]]; then
    warn "No EFI System Partition (EF00) found. Skipping EFI setup."
else
    log "Syncing EFI partition (part${EFI_PART_NUM})..."

    EFI_HEALTHY="/dev/disk/by-id/${HEALTHY_BASE}-part${EFI_PART_NUM}"
    EFI_NEW="${NEW_DRIVE_PATH}-part${EFI_PART_NUM}"

    TMPDIR_HEALTHY=$(mktemp -d /tmp/efi-healthy.XXXX)
    TMPDIR_NEW=$(mktemp -d /tmp/efi-new.XXXX)

    mount -o ro "$EFI_HEALTHY" "$TMPDIR_HEALTHY"
    mount "$EFI_NEW" "$TMPDIR_NEW"

    DIFF_OUTPUT=$(diff -rq "$TMPDIR_HEALTHY" "$TMPDIR_NEW" 2>&1 || true)
    if [[ -z "$DIFF_OUTPUT" ]]; then
        ok "EFI partitions are already in sync."
    else
        log "EFI partitions differ — syncing from healthy drive..."
        rsync -a --delete "$TMPDIR_HEALTHY/" "$TMPDIR_NEW/"
        ok "EFI partition synced."
    fi

    umount "$TMPDIR_HEALTHY" "$TMPDIR_NEW"
    rmdir "$TMPDIR_HEALTHY" "$TMPDIR_NEW"

    # --- Update EFI boot entries ---
    log "Updating EFI boot entries..."

    # Get the PARTUUID of the new drive's EFI partition
    NEW_EFI_PARTUUID=$(blkid -s PARTUUID -o value "$EFI_NEW")

    # Check if a boot entry already exists for this PARTUUID
    EXISTING_ENTRY=$(efibootmgr -v 2>/dev/null | grep -i "$NEW_EFI_PARTUUID" | grep -oP 'Boot\K[0-9]+' | head -1 || true)

    if [[ -n "$EXISTING_ENTRY" ]]; then
        ok "EFI boot entry Boot${EXISTING_ENTRY} already exists for new drive."
    else
        # Detect bootloader path from existing entries
        BOOT_LOADER=$(efibootmgr -v 2>/dev/null | grep "systemd-boot" | grep -oP 'File\(\K[^)]+' | head -1 || true)
        if [[ -z "$BOOT_LOADER" ]]; then
            BOOT_LOADER='\EFI\systemd\systemd-bootx64.efi'
            warn "Could not detect bootloader path; defaulting to $BOOT_LOADER"
        fi

        log "Creating EFI boot entry for new drive..."
        efibootmgr -c -d "$NEW_DRIVE_PATH" -p "$EFI_PART_NUM" \
            -L "Linux Boot Manager" -l "$BOOT_LOADER" >/dev/null
        ok "EFI boot entry created for new drive."
    fi

    # Remove stale boot entries for the old failed drive
    if [[ -n "$OLD_DRIVE_NAME" ]]; then
        # Extract the old drive's EFI partition PARTUUID from the "was" path
        OLD_BASE="${OLD_DRIVE_NAME%%-part[0-9]*}"
        OLD_EFI_PART="/dev/disk/by-id/$(basename "$OLD_BASE")-part${EFI_PART_NUM}"

        # The old drive is gone, so we identify stale entries by elimination:
        # any Linux Boot Manager entry whose PARTUUID doesn't match healthy or new drive
        HEALTHY_EFI_PARTUUID=$(blkid -s PARTUUID -o value "$EFI_HEALTHY")

        while IFS= read -r line; do
            BOOT_NUM=$(echo "$line" | grep -oP 'Boot\K[0-9]+')
            LINE_PARTUUID=$(echo "$line" | grep -oiP '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1 || true)

            if [[ -n "$LINE_PARTUUID" && "$LINE_PARTUUID" != "$HEALTHY_EFI_PARTUUID" && "$LINE_PARTUUID" != "$NEW_EFI_PARTUUID" ]]; then
                if echo "$line" | grep -qi "Linux Boot Manager"; then
                    log "Removing stale boot entry Boot${BOOT_NUM} (PARTUUID: ${LINE_PARTUUID})..."
                    efibootmgr -b "$BOOT_NUM" -B >/dev/null
                    ok "Removed Boot${BOOT_NUM}."
                fi
            fi
        done < <(efibootmgr -v 2>/dev/null | grep "^Boot[0-9]")
    fi
fi

# ---------------------------------------------------------------------------
# Step 6: Final status
# ---------------------------------------------------------------------------
echo ""
echo "========================================"
log "Final pool status:"
echo "========================================"
zpool status "$POOL"
echo ""

FINAL_STATE=$(zpool get -H -o value health "$POOL")
if [[ "$FINAL_STATE" == "ONLINE" ]]; then
    ok "Drive replacement complete. Pool '$POOL' is ONLINE."
else
    warn "Pool '$POOL' is $FINAL_STATE. Review status above."
fi

# ---------------------------------------------------------------------------
# Step 7: Log to zfs_drive_replacement.log
# ---------------------------------------------------------------------------
LOG_FILE="$HOME/zfs_drive_replacement.log"
{
    echo ""
    echo "--- Drive Replacement $(date '+%Y-%m-%d %H:%M:%S') ---"
    echo "Pool: $POOL"
    echo "Failed device: $FAILED_DEV"
    [[ -n "$OLD_DRIVE_NAME" ]] && echo "Old drive: $OLD_DRIVE_NAME"
    echo "Replacement: ${NEW_DRIVE_ID}-part${ZFS_PART_NUM}"
    echo "Healthy mirror: $HEALTHY_DEV"
    echo "Final state: $FINAL_STATE"
    echo "---"
} >> "$LOG_FILE"
log "Appended summary to $LOG_FILE"