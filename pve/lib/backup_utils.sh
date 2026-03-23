#!/bin/bash
###############################################################################
# Script Name: backup_utils.sh
# Description: Shared backup utilities for Proxmox VE configuration backups
# Purpose: Centralized backup functions to eliminate code duplication
#
# Author: Will Bradshaw (Bullium Consulting) <wbradshaw@bullium.com>
# Version: 1.0
# Date: 2025-07-08
# Support: support@bullium.com
###############################################################################

# Default configuration - can be overridden
DEFAULT_SRC_DIRS=(
    "/etc/systemd"
    "/etc/systemd/system"
    "/etc/fstab"
    "/etc/pve"
    "/etc/network/interfaces"
    "/etc/hosts"
    "/etc/resolv.conf"
    "/etc/cron.d"
    "/etc/vzdump.conf"
)

DEFAULT_RETENTION_DAYS=90
DEFAULT_COMPRESS_ALGO="zstd"

# Global variables
BACKUP_ROOT=""
HOSTNAME=""
RETENTION_DAYS=""
COMPRESS_ALGO=""
DATE_STAMP=""
LOG_FILE=""
BACKUP_DIR=""
SRC_DIRS=()

# Initialize backup configuration
init_backup_config() {
    local backup_root="$1"
    local retention_days="${2:-$DEFAULT_RETENTION_DAYS}"
    local compress_algo="${3:-$DEFAULT_COMPRESS_ALGO}"
    
    BACKUP_ROOT="$backup_root"
    HOSTNAME=$(hostname -s)
    RETENTION_DAYS="$retention_days"
    COMPRESS_ALGO="$compress_algo"
    DATE_STAMP=$(date +"%Y%m%d_%H%M%S")
    LOG_FILE="${BACKUP_ROOT}/${HOSTNAME}_config_backup_${DATE_STAMP}.log"
    BACKUP_DIR="${BACKUP_ROOT}/${HOSTNAME}_${DATE_STAMP}"
    
    # Use default source directories if not set
    if [[ ${#SRC_DIRS[@]} -eq 0 ]]; then
        SRC_DIRS=("${DEFAULT_SRC_DIRS[@]}")
    fi
}

# Set custom source directories
set_source_dirs() {
    SRC_DIRS=("$@")
}

# Setup logging and backup directory
setup_backup_environment() {
    # Create backup directory
    mkdir -p "${BACKUP_DIR}" || {
        echo "Error: Failed to create backup directory: ${BACKUP_DIR}"
        exit 1
    }
    
    # Create log directory if needed
    mkdir -p "$(dirname "${LOG_FILE}")" || {
        echo "Error: Failed to create log directory"
        exit 1
    }
    
    # Setup logging
    exec > >(tee -a "${LOG_FILE}") 2>&1
    
    # Setup exit trap
    trap 'echo -e "\nBackup completed at $(date +"%Y-%m-%d %T") with exit code $?"' EXIT
}

# Log backup start information
log_backup_start() {
    echo "Starting Proxmox VE configuration backup"
    echo "Hostname: ${HOSTNAME}"
    echo "Backup Directory: ${BACKUP_DIR}"
    echo "Retention: ${RETENTION_DAYS} days"
    echo "Compression: ${COMPRESS_ALGO}"
    echo "Date: $(date +"%Y-%m-%d %T")"
    echo "----------------------------------------"
}

# Backup a single directory
backup_directory() {
    local src_dir="$1"
    
    if [[ ! -d "$src_dir" ]]; then
        echo "Warning: Source directory does not exist: $src_dir"
        return 1
    fi
    
    echo "Backing up: $src_dir"
    local dest_name=$(basename "$src_dir")
    
    # Handle root directory special case
    if [[ "$src_dir" == "/" ]]; then
        dest_name="root"
    fi
    
    cp -a "$src_dir" "${BACKUP_DIR}/${dest_name}" 2>/dev/null || {
        echo "Error: Failed to backup $src_dir"
        return 1
    }
    
    echo "  ✓ Backed up $src_dir"
    return 0
}

# Perform backup of all configured directories
perform_backup() {
    local success_count=0
    local total_count=${#SRC_DIRS[@]}
    
    echo "Backing up ${total_count} directories..."
    echo
    
    for src_dir in "${SRC_DIRS[@]}"; do
        if backup_directory "$src_dir"; then
            ((success_count++))
        fi
    done
    
    echo
    echo "Backup Summary:"
    echo "  Successful: ${success_count}/${total_count}"
    
    if [[ $success_count -lt $total_count ]]; then
        echo "  Warning: Some directories failed to backup"
        return 1
    fi
    
    return 0
}

# Compress backup directory
compress_backup() {
    local archive_name="${HOSTNAME}_config_${DATE_STAMP}.tar.${COMPRESS_ALGO}"
    local archive_path="${BACKUP_ROOT}/${archive_name}"
    
    echo "Compressing backup..."
    
    case "$COMPRESS_ALGO" in
        zstd)
            tar -cf - -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")" | \
            zstd -3 -o "$archive_path" || return 1
            ;;
        gzip)
            tar -czf "$archive_path" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")" || return 1
            ;;
        xz)
            tar -cJf "$archive_path" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")" || return 1
            ;;
        *)
            echo "Error: Unsupported compression algorithm: $COMPRESS_ALGO"
            return 1
            ;;
    esac
    
    echo "  ✓ Created archive: $archive_path"
    
    # Get archive size
    local size=$(du -h "$archive_path" | cut -f1)
    echo "  Archive size: $size"
    
    # Remove uncompressed backup directory
    rm -rf "$BACKUP_DIR"
    echo "  ✓ Cleaned up temporary files"
    
    return 0
}

# Clean up old backups based on retention policy
cleanup_old_backups() {
    echo "Cleaning up backups older than ${RETENTION_DAYS} days..."
    
    local cleanup_count=0

    # Find and remove old backup directories
    find "$BACKUP_ROOT" -maxdepth 1 -type d -name "${HOSTNAME}_*" -mtime +"${RETENTION_DAYS}" -exec rm -rf {} \; 2>/dev/null

    # Find and remove old archive files
    while read -r old_file; do
        rm -f "$old_file"
        echo "  Removed old backup: $(basename "$old_file")"
        ((cleanup_count++))
    done < <(find "$BACKUP_ROOT" -maxdepth 1 -type f -name "${HOSTNAME}_config_*.tar.*" -mtime +"${RETENTION_DAYS}" 2>/dev/null)

    if [[ $cleanup_count -eq 0 ]]; then
        echo "  No old backups to clean up"
    else
        echo "  Cleaned up $cleanup_count old backup(s)"
    fi
}

# Main backup function - orchestrates the entire process
run_backup() {
    log_backup_start
    
    if ! perform_backup; then
        echo "Error: Backup failed"
        exit 1
    fi
    
    if ! compress_backup; then
        echo "Error: Compression failed"
        exit 1
    fi
    
    cleanup_old_backups
    
    echo
    echo "Backup completed successfully!"
    echo "Log file: $LOG_FILE"
}

# Validation function
validate_backup_root() {
    local backup_root="$1"
    
    if [[ -z "$backup_root" ]]; then
        echo "Error: Backup root directory not specified"
        return 1
    fi
    
    if [[ ! -d "$backup_root" ]]; then
        echo "Error: Backup root directory does not exist: $backup_root"
        return 1
    fi
    
    if [[ ! -w "$backup_root" ]]; then
        echo "Error: Backup root directory is not writable: $backup_root"
        return 1
    fi
    
    return 0
}