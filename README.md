# Proxmox LXC GitHub Actions Runner

This script provisions a **self-hosted GitHub Actions runner** inside a **Proxmox LXC container**, using **Ubuntu 25.04** and **Docker**.

It is intended for **test, staging, or prod-like environments** where you want a runner that closely mirrors real infrastructure while still being lightweight.

---

## What this script does

- Downloads the Ubuntu 25.04 LXC template
- Creates a privileged LXC container on Proxmox
- Configures networking via DHCP
- Installs base system packages
- Installs Docker (Docker Engine Community)
- Installs and registers a GitHub Actions runner
- Runs the runner as a systemd service
- Ensures the container starts on boot

---

## Architecture and assumptions

- Proxmox host is **amd64 (x86_64)**
- GitHub runner architecture: **x64**
- Container is **privileged** (required for Docker-in-LXC without hacks)
- Networking is provided via a bridge (default: `vmbr0`)
- Outbound internet access is available
- DHCP reservation has been made against the MAC address

---

## Prerequisites

### Proxmox host
- Proxmox VE 8.x or newer
- Internet access
- Enough storage on the selected storage backend (default: `local-lvm`)
- `pveam`, `pct` available (standard Proxmox install)

### GitHub
- A repository where you have **admin access**
- Ability to create **self-hosted runners**
- A **runner registration token** (generated via GitHub UI)

---

## Getting the GitHub runner token

1. Go to your GitHub repository
2. Navigate to:  
   `Settings → Actions → Runners`
3. Click **New self-hosted runner**
4. Select:
   - OS: **Linux**
   - Architecture: **x64**
5. Copy:
   - The repository URL
   - The registration token (expires in ~1 hour)

These values are required before running the script.

---

## Configuration

Edit the following section at the top of the script:

```bash
CTID=101
HOSTNAME="github-runner"
STORAGE="local-lvm"
DISK_SIZE_GB=15
CORES=2
MEMORY_MB=2048
SWAP_MB=2048
BRIDGE="vmbr0"
MAC_ADDRESS="BC:24:11:1A:E2:52"

REPO_URL="https://github.com/<OWNER>/<REPOSITORY>"
RUNNER_TOKEN="<RUNNER_REGISTRATION_TOKEN>"