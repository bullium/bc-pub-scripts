# bc-scripts-public
# Scripts Repository

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
![Version](https://img.shields.io/badge/version-4.1.0-green.svg)
![Shell](https://img.shields.io/badge/shell-bash%204%2B-yellow.svg)

Bullium Consulting Public avaialble scripts.

Bash scripts repository for system administration, security assessment, and monitoring — primarily targeting Linux, Proxmox VE, and Oracle environments.

## Getting Started

```bash
# Clone the repository
git clone ssh://git@github.com/bullium/bc-pub-scripts.git
cd scripts

# Set up development environment (git hooks, verify dependencies)
bash setup.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for code style, branching, and testing guidelines.

## Structure

### Proxmox VE (PVE) Scripts

| Location | Script | Purpose/Description |
|----------|--------|---------------------|
| pve/ | deploy_proxmox_monitoring_stack_v1.sh | Deploy Proxmox monitoring stack (InfluxDB 2.x + Grafana 10.x). |
| pve/ | pve_config_backup.sh | Modular Proxmox VE config backup to external HDD using shared utilities. |
| pve/ | pve_config_backup_nfs.sh | Modular Proxmox VE config backup to NFS share using shared utilities. |
| pve/ | pve_config_backup_usb.sh | Modular Proxmox VE config backup to USB device using shared utilities. |
| pve/ | pveq_config_backup_nfs.sh | Modular QDevice config backup to NFS (excludes /etc/pve) using shared utilities. |
| pve/ | pve_status.sh | Generate Proxmox VE node status snapshot. |
| pve/ | pve_storage_check.sh | Check PVE datastore status. |
| pve/ | quorum_check.sh | Check Raspberry Pi quorum. |
| pve/ | rpi_version_check.sh | Show Raspberry Pi version. |
| pve/ | zfs_replace_drive.sh | Automate ZFS mirror drive replacement with EFI sync and boot entry management (Proxmox/systemd-boot). |
| pve/ | ha_tool.sh | Safely check status, stop, and start the Proxmox HA manager across a cluster. |
| pve/ | update_ts_cert.sh | Rotate Tailscale TLS certificate and apply it to the Proxmox VE web interface. |
| pve/lib/ | backup_utils.sh | Shared backup utility functions for PVE configuration scripts. 

## Documentation

| Document | Description |
|----------|-------------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Code style, branching, testing, PR process |
| [CHANGELOG.md](CHANGELOG.md) | Version history (Keep a Changelog format) |
| [LICENSE](LICENSE) | Apache 2.0 License |
| [docs/usage.md](docs/usage.md) | General usage examples |

## Testing

Tests use [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

```bash
# Run the full suite
bats tests/bats/

# Run via the runner script
bash tests/test_linux_config_backup.sh
```

See [tests/README.md](tests/README.md) for setup and how to write new tests.

---

*Last updated: 2026-03-23*