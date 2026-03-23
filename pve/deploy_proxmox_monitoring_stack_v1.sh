#!/bin/bash
###############################################################################
# Script Name: deploy_proxmox_monitoring_stack-v1.sh
# Description: Deploys InfluxDB 2.x and Grafana 10.x for Proxmox monitoring with secure credentials.
#
# Author: Will Bradshaw (Bullium Consulting) <wbradshaw@bullium.com>
# Version: 1.0
# Date: 2025-07-05
# Support: support@bullium.com
###############################################################################

INFLUX_IP="192.168.69.10"
GRAFANA_IP="192.168.69.11"
SUBNET_MASK="/24"
GATEWAY="192.168.69.1"
INFLUX_ID=117
GRAFANA_ID=118

# Security Credentials — sourced from external config or prompted at runtime
CREDS_FILE="${CREDS_FILE:-./monitoring_creds.conf}"
if [ -f "$CREDS_FILE" ]; then
    echo "[INFO] Loading credentials from $CREDS_FILE"
    # shellcheck source=/dev/null
    source "$CREDS_FILE"
else
    echo "[INFO] No credentials file found at $CREDS_FILE — prompting for input."
    read -r -p "InfluxDB org name (lowercase, no spaces): " INFLUX_ORG
    read -r -p "InfluxDB admin username: " INFLUX_ADMIN_USER
    read -r -s -p "InfluxDB admin password (20+ chars recommended): " INFLUX_ADMIN_PASS; echo
    read -r -s -p "InfluxDB API token: " INFLUX_TOKEN; echo
    read -r -p "InfluxDB bucket name: " INFLUX_BUCKET
    read -r -p "Grafana org display name: " GRAFANA_ORG
    read -r -p "Grafana admin username: " GRAFANA_ADMIN_USER
    read -r -s -p "Grafana admin password (16+ chars recommended): " GRAFANA_ADMIN_PASS; echo
fi

# Validate required variables are set
for var in INFLUX_ORG INFLUX_ADMIN_USER INFLUX_ADMIN_PASS INFLUX_TOKEN INFLUX_BUCKET GRAFANA_ORG GRAFANA_ADMIN_USER GRAFANA_ADMIN_PASS; do
    if [ -z "${!var:-}" ]; then
        echo "[ERROR] Required variable $var is not set. Check $CREDS_FILE or provide it at the prompt."
        exit 1
    fi
done

### InfluxDB Deployment ###
pct create $INFLUX_ID \
  local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst \
  --hostname influxdb-proxmox \
  --cores 2 \
  --memory 2048 \
  --net0 name=eth0,bridge=vmbr0,ip=${INFLUX_IP}${SUBNET_MASK},gw=$GATEWAY \
  --storage local-lvm \
  --unprivileged 1 \
  --onboot 1

# shellcheck disable=SC1078,SC2027  # Heredoc embedded in bash -c string; quotes intentional
pct exec $INFLUX_ID -- bash -c "cat << EOF > /root/influxdb-setup.sh
#!/bin/bash
# Install InfluxDB with secure configuration
wget -q https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.6-amd64.deb
dpkg -i influxdb2-2.7.6-amd64.deb

# Configure authentication before service start
cat << INFLUXCONF > /etc/influxdb/config.toml
[http]
  auth-enabled = true
INFLUXCONF

systemctl enable influxdb
systemctl start influxdb

# Wait for service initialization
until curl -s http://localhost:8086/health; do sleep 2; done

# Setup with secure credentials
influx setup --force \\
  --username $INFLUX_ADMIN_USER \\
  --password "$INFLUX_ADMIN_PASS" \\
  --org $INFLUX_ORG \\
  --bucket $INFLUX_BUCKET \\
  --token "$INFLUX_TOKEN"

# Create read-only user for Grafana
influx user create \\
  --name grafana_reader \\
  --password \${GRAFANA_READER_PASS:-ChangeMeGrafanaReader} \\
  --org $INFLUX_ORG 

influx auth create \\
  --org $INFLUX_ORG \\
  --user grafana_reader \\
  --read-buckets
EOF"

pct exec $INFLUX_ID -- chmod +x /root/influxdb-setup.sh
pct exec $INFLUX_ID -- /root/influxdb-setup.sh

### Grafana Deployment ###
pct create $GRAFANA_ID \
  local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst \
  --hostname grafana-proxmox \
  --cores 2 \
  --memory 2048 \
  --net0 name=eth0,bridge=vmbr0,ip=${GRAFANA_IP}${SUBNET_MASK},gw=$GATEWAY \
  --storage local-lvm \
  --unprivileged 1 \
  --onboot 1

pct exec $GRAFANA_ID -- bash -c "cat << EOF > /root/grafana-setup.sh
#!/bin/bash
# Install Grafana with secure configuration
apt-get install -y apt-transport-https software-properties-common wget gnupg2
wget -q -O - https://packages.grafana.com/gpg.key | gpg --dearmor > /etc/apt/trusted.gpg.d/grafana.gpg
echo \"deb https://packages.grafana.com/oss/deb stable main\" > /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y grafana

# Configure persistent security settings
mkdir -p /etc/grafana
cat << GRAFANAINI > /etc/grafana/grafana.ini
[security]
admin_user = $GRAFANA_ADMIN_USER
admin_password = $GRAFANA_ADMIN_PASS
disable_initial_admin_creation = false
disable_gravatar = true

[auth]
disable_login_form = false
disable_signout_menu = true

[users]
allow_sign_up = false
auto_assign_org = true
auto_assign_org_role = Editor
GRAFANAINI

# Apply configuration and start service
systemctl enable grafana-server
systemctl start grafana-server

# Verify installation
until curl -s http://localhost:3000; do sleep 2; done

# Configure InfluxDB datasource securely
curl -X POST \"http://${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASS}@localhost:3000/api/datasources\" \\
  -H \"Content-Type: application/json\" \\
  -d '{
    \"name\": \"Proxmox InfluxDB\",
    \"type\": \"influxdb\",
    \"url\": \"http://${INFLUX_IP}:8086\",
    \"access\": \"proxy\",
    \"jsonData\": {
      \"defaultBucket\": \"$INFLUX_BUCKET\",
      \"organization\": \"$GRAFANA_ORG\",
      \"version\": \"Flux\"
    },
    \"secureJsonData\": {
      \"token\": \"${INFLUX_TOKEN}\"
    }
  }'
EOF"

pct exec $GRAFANA_ID -- chmod +x /root/grafana-setup.sh
pct exec $GRAFANA_ID -- /root/grafana-setup.sh

### Final Output ###
set -euo pipefail

echo "Deployment Complete"
echo "InfluxDB: https://${INFLUX_IP}:8086"
echo "  - Admin: ${INFLUX_ADMIN_USER}"
echo "  - Pass: ${INFLUX_ADMIN_PASS}"
echo "Grafana: https://${GRAFANA_IP}:3000"
echo "  - Admin: ${GRAFANA_ADMIN_USER}"
echo "  - Pass: ${GRAFANA_ADMIN_PASS}"

# Security Recommendations
echo -e "\n\e[1;33mSecurity Recommendations:\e[0m"
echo "1. Enable HTTPS on both services"
echo "2. Configure firewall rules:"
echo "   - Allow only 3000/tcp from trusted networks (Grafana)"
echo "   - Restrict 8086/tcp to Grafana IP only (InfluxDB)"
echo "3. Rotate credentials after initial deployment"
echo "4. Set up backup schedules for both databases"
echo "5. Monitor login attempts and set up alerts"

