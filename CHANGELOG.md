# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-23

### Added

- **PVE Backup Scripts**: Modular Proxmox VE configuration backup system
  - `pve_config_backup.sh` — backup to external HDD
  - `pve_config_backup_nfs.sh` — backup to NFS share
  - `pve_config_backup_usb.sh` — backup to USB/external SSD
  - `pveq_config_backup_nfs.sh` — QDevice backup to NFS (excludes /etc/pve)
  - `pve/lib/backup_utils.sh` — shared backup utility library
- **PVE Monitoring Scripts**:
  - `pve_status.sh` — node status snapshot (cluster, services, VMs, containers)
  - `pve_storage_check.sh` — datastore status and usage check
  - `quorum_check.sh` — QDevice cluster quorum status
- **PVE Maintenance Scripts**:
  - `zfs_replace_drive.sh` — automated ZFS mirror drive replacement with EFI sync
  - `update_ts_cert.sh` — Tailscale TLS certificate rotation for PVE web UI
  - `ha_tool.sh` — Proxmox HA Manager control across cluster nodes
- **PVE Deployment Scripts**:
  - `deploy_proxmox_monitoring_stack_v1.sh` — InfluxDB 2.x + Grafana 10.x deployment
- **Utility Scripts**:
  - `rpi_version_check.sh` — Raspberry Pi hardware model identification
- Project scaffolding: README, CONTRIBUTE.md, LICENSE (Apache 2.0), setup.sh
