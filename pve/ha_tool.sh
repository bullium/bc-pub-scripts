#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024-2026 Bullium Consulting

# ==============================================================================
#
# Proxmox HA Manager Control Script
#
# Description: A production-ready script to safely check status, stop (disable),
#              and start (enable) the Proxmox High Availability manager
#              across an entire cluster.
#
# Usage: ./ha_tool.sh [status|stop|start]
#
#
# Author: Will Bradshaw (Bullium Consulting) <wbradshaw@bullium.com>
# Version: 1.0
# Support: support@bullium.com
###############################################################################
# ==============================================================================

# --- Script Configuration ---

# An array of all node hostnames or IP addresses in the Proxmox cluster.
# This is the only section you should need to edit for your environment.
readonly NODES=("pve1" "pve2" "pve3")

# The SSH user with key-based access to all nodes.
readonly SSH_USER="root"

# The node from which cluster-wide commands will be issued. Any node will do.
readonly MASTER_NODE="${NODES[0]}"

# --- Safety & Error Handling ---

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# The return value of a pipeline is the status of the last command to fail.
set -euo pipefail

# --- Functions ---

# Prints a formatted informational message.
log_info() {
  echo "[INFO] $1"
}

# Prints a formatted error message to stderr.
log_error() {
  echo >&2 "[ERROR] $1"
}

# Displays the script's usage instructions.
usage() {
  echo "Usage: $0 [status|stop|start]"
  echo "  status:  Check the HA service status on all cluster nodes."
  echo "  stop:    Disables the HA service for the entire cluster."
  echo "  start:   Enables the HA service for the entire cluster."
}

# Executes a given command on the designated master node.
# Proxmox HA enable/disable are cluster-wide commands and only need to be run once.
# Globals:
#   SSH_USER
#   MASTER_NODE
# Arguments:
#   $1: The command to execute.
run_on_master() {
  local command_to_run="$1"
  log_info "Executing command on master node (${MASTER_NODE}): '${command_to_run}'"
  if ! ssh -o ConnectTimeout=5 "${SSH_USER}@${MASTER_NODE}" "${command_to_run}"; then
    log_error "Failed to execute command on ${MASTER_NODE}. Aborting."
    exit 1
  fi
}

# Checks the HA status on every node in the cluster.
# Globals:
#   NODES
#   SSH_USER
ha_status() {
  log_info "Querying HA status on all cluster nodes..."
  for node in "${NODES[@]}"; do
    echo "-----------------------------------------------------"
    log_info "Node: ${node}"
    echo "-----------------------------------------------------"
    # Execute the command on each node and handle potential connection errors.
    if ! ssh -o ConnectTimeout=5 "${SSH_USER}@${node}" "ha-manager status"; then
      log_error "Could not retrieve status from ${node}. It may be offline."
    fi
    echo # Add a blank line for readability
  done
}

# Disables the Proxmox HA Manager cluster-wide.
ha_stop() {
  log_info "Requesting to STOP (disable) the Proxmox HA Manager..."
  run_on_master "ha-manager disable"
  log_info "✅ HA Manager successfully disabled. Verifying status..."
  ha_status
}

# Enables the Proxmox HA Manager cluster-wide.
ha_start() {
  log_info "Requesting to START (enable) the Proxmox HA Manager..."
  run_on_master "ha-manager enable"
  log_info "✅ HA Manager successfully enabled. Verifying status..."
  ha_status
}

# --- Main Script Logic ---

main() {
  # Ensure an action was provided
  if [[ $# -ne 1 ]]; then
    log_error "No action specified."
    usage
    exit 1
  fi

  local action="$1"

  # Process the requested action
  case "${action}" in
    status)
      ha_status
      ;;
    stop)
      ha_stop
      ;;
    start)
      ha_start
      ;;
    *)
      log_error "Invalid action: '${action}'."
      usage
      exit 1
      ;;
  esac
}

# Execute the main function with all script arguments
main "$@"