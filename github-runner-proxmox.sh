#!/usr/bin/env bash
set -euo pipefail

#
# Proxmox LXC GitHub Actions Runner bootstrap
# - Ubuntu 25.04
# - Docker inside LXC
# - Repo-level self-hosted runner
#

############################
# USER-EDITABLE SETTINGS
############################

# Proxmox container settings
CTID=101
HOSTNAME="github-runner"
STORAGE="local-lvm"
DISK_SIZE_GB=15
CORES=2
MEMORY_MB=2048
SWAP_MB=2048
BRIDGE="vmbr0"
MAC_ADDRESS="BC:24:11:1A:E2:52"

# Ubuntu template
TEMPLATE_NAME="ubuntu-25.04-standard_25.04-1.1_amd64.tar.zst"
TEMPLATE_PATH="/var/lib/vz/template/cache/${TEMPLATE_NAME}"

# GitHub Actions runner
RUNNER_VERSION="2.331.0"
RUNNER_ARCHIVE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_ARCHIVE}"

# GitHub (FILL THESE IN)
REPO_URL="https://github.com/<OWNER>/<REPOSITORY>"
RUNNER_TOKEN="<RUNNER_REGISTRATION_TOKEN>"

############################
# Helpers
############################
log() {
  echo "[github-runner] $1"
}

############################
# Preconditions
############################
if [[ "$REPO_URL" == *"<"* || "$RUNNER_TOKEN" == *"<"* ]]; then
  echo "ERROR: REPO_URL and RUNNER_TOKEN must be set before running this script."
  exit 1
fi

############################
# Template handling
############################
if [[ ! -f "$TEMPLATE_PATH" ]]; then
  log "Downloading Ubuntu LXC template"
  pveam update
  pveam download local "$TEMPLATE_NAME"
fi

############################
# Container creation
############################
log "Creating LXC container ${CTID}"

pct create "$CTID" "$TEMPLATE_PATH" \
  -hostname "$HOSTNAME" \
  -storage "$STORAGE" \
  -rootfs "${STORAGE}:${DISK_SIZE_GB}" \
  -cores "$CORES" \
  -memory "$MEMORY_MB" \
  -swap "$SWAP_MB" \
  -net0 "name=eth0,bridge=${BRIDGE},ip=dhcp,hwaddr=${MAC_ADDRESS}" \
  -features nesting=1,keyctl=1 \
  -unprivileged 0 \
  -onboot 1

pct start "$CTID"
sleep 8

############################
# DNS configuration
############################
log "Configuring DNS"

pct exec "$CTID" -- bash -c "
cat <<EOF >/etc/systemd/resolved.conf
[Resolve]
DNS=8.8.8.8 1.1.1.1
FallbackDNS=9.9.9.9
EOF

systemctl restart systemd-resolved
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
"

############################
# Base packages
############################
log "Installing base packages"

pct exec "$CTID" -- bash -c "
apt update -y
apt install -y \
  ca-certificates \
  curl \
  git \
  jq \
  locales \
  zip

locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
"

############################
# Docker
############################
log "Installing Docker"

pct exec "$CTID" -- bash -c "
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker
docker version
"

############################
# GitHub Actions Runner
############################
log "Installing GitHub Actions runner"

pct exec "$CTID" -- bash -c "
mkdir -p /opt/actions-runner
cd /opt/actions-runner

curl -L -o ${RUNNER_ARCHIVE} ${RUNNER_URL}
tar xzf ${RUNNER_ARCHIVE}

export RUNNER_ALLOW_RUNASROOT=1
./config.sh \
  --unattended \
  --url ${REPO_URL} \
  --token ${RUNNER_TOKEN} \
  --name ${HOSTNAME} \
  --labels proxmox,lxc,docker,test

./svc.sh install
./svc.sh start
"

log "Runner installation complete"