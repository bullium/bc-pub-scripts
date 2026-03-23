# Usage Guide for bc-scripts-public

## Overview
This repository contains Bash scripts for Proxmox VE system administration, backup, monitoring, and maintenance.

## Directory Structure
- pve/: Scripts for Proxmox VE
  - pve/lib/: Shared backup utility functions
- docs/: Documentation and usage examples
- tests/: BATS test scripts

## How to Use the Scripts

### General Script Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/bullium/bc-pub-scripts.git
   cd bc-pub-scripts
   ```
2. **Browse to the relevant directory:**
   - For Proxmox scripts: `cd pve`
3. **Run a script:**
   ```bash
   bash script_name.sh
   # or make it executable and run directly
   chmod +x script_name.sh
   ./script_name.sh
   ```

## Example Commands
- Deploy Proxmox monitoring stack:
  ```bash
  bash pve/deploy_proxmox_monitoring_stack_v1.sh
  ```
- Back up PVE configuration to NFS:
  ```bash
  bash pve/pve_config_backup_nfs.sh
  ```
- Check cluster quorum status:
  ```bash
  bash pve/quorum_check.sh
  ```
- Generate PVE node status report:
  ```bash
  bash pve/pve_status.sh
  ```
- Replace a ZFS mirror drive:
  ```bash
  sudo bash pve/zfs_replace_drive.sh <pool> <new-drive-id>
  ```
- Manage HA across the cluster:
  ```bash
  bash pve/ha_tool.sh status
  ```

## Developer Setup

```bash
# Clone and set up development environment
git clone https://github.com/bullium/bc-pub-scripts.git
cd bc-pub-scripts
bash setup.sh    # Configures git hooks, verifies dependencies
```

This installs:
- **Pre-commit hook**: Runs ShellCheck on staged `.sh` files
- **Commit-msg hook**: Validates conventional commit format

## Running Tests

```bash
# Run the full BATS test suite (from repo root)
bats tests/bats/

# Run PVE tests only
bats tests/bats/pve.bats
```

## Linting

```bash
# Lint a specific script
shellcheck path/to/script.sh
```

## Branching & Contribution

- Use `feature/*` and `bugfix/*` branches from `main`
- Open pull requests for review and merging
- Use conventional commit messages (`feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`)
- See [CONTRIBUTE.md](../CONTRIBUTE.md) for full guidelines
- See [CHANGELOG.md](../CHANGELOG.md) for version history

---
_Last updated: 2026-03-23_
