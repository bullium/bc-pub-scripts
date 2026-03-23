# bc-scripts-public

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
![Version](https://img.shields.io/badge/version-v1.0.0-green.svg)
![Shell](https://img.shields.io/badge/shell-bash%204%2B-yellow.svg)

Bullium Consulting publicly available scripts.

Bash scripts repository for system administration, security assessment, and monitoring — primarily targeting Proxmox VE environments.


## Getting Started

```bash
# Clone the repository
git clone https://github.com/bullium/bc-pub-scripts
cd bc-scripts-public

# Set up development environment (git hooks, verify dependencies)
bash setup.sh
```

See [CONTRIBUTE.md](CONTRIBUTE.md) for code style, branching, and testing guidelines.

## Structure

### Proxmox VE (PVE) Scripts

| Location | Script | Purpose/Description |
|----------|--------|---------------------|
| pve/ | deploy_proxmox_monitoring_stack_v1.sh | Deploy Proxmox monitoring stack (InfluxDB 2.x + Grafana 10.x). |
| pve/ | ha_tool.sh | Safely check status, stop, and start the Proxmox HA manager across a cluster. |
| pve/ | pve_config_backup.sh | Modular Proxmox VE config backup to external HDD using shared utilities. |
| pve/ | pve_config_backup_nfs.sh | Modular Proxmox VE config backup to NFS share using shared utilities. |
| pve/ | pve_config_backup_usb.sh | Modular Proxmox VE config backup to USB device using shared utilities. |
| pve/ | pve_status.sh | Generate Proxmox VE node status snapshot. |
| pve/ | pve_storage_check.sh | Check PVE datastore status. |
| pve/ | pveq_config_backup_nfs.sh | Modular QDevice config backup to NFS (excludes /etc/pve) using shared utilities. |
| pve/ | quorum_check.sh | Check Raspberry Pi quorum device status. |
| pve/ | rpi_version_check.sh | Show Raspberry Pi hardware model information. |
| pve/ | update_ts_cert.sh | Rotate Tailscale TLS certificate and apply it to the Proxmox VE web interface. |
| pve/ | zfs_replace_drive.sh | Automate ZFS mirror drive replacement with EFI sync and boot entry management (Proxmox/systemd-boot). |
| pve/lib/ | backup_utils.sh | Shared backup utility functions for PVE configuration scripts. |

## Documentation

| Document | Description |
|----------|-------------|
| [CONTRIBUTE.md](CONTRIBUTE.md) | Code style, branching, testing, PR process |
| [CHANGELOG.md](CHANGELOG.md) | Version history (Keep a Changelog format) |
| [LICENSE](LICENSE) | Apache 2.0 License |
| [docs/usage.md](docs/usage.md) | General usage examples |

## Testing

Tests use [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

```bash
# Run the full suite
bats tests/bats/

# Run PVE tests only
bats tests/bats/pve.bats
```

See [tests/README.md](tests/README.md) for setup and how to write new tests.

---

*Last updated: 2026-03-23*
