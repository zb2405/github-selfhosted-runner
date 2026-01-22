# Proxmox LXC GitHub Actions Runner

This script provisions a **self-hosted GitHub Actions runner** inside a **Proxmox LXC container**, using **Ubuntu 25.04** and **Docker**.

It is intended for **test or staging** where you want a runner that closely mirrors real infrastructure while still being lightweight.

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

### Proxmox host prerequisites

Before running the script, verify the following on the **Proxmox host**.

### Container ID (CTID)

Ensure the CTID you plan to use is not already allocated:

```bash
pct list
```

If the ID is in use, update the `CTID` variable in the script.

---

## Network bridge

The script attaches the container network interface to a Linux bridge on the Proxmox host.

Default bridge:
- `vmbr0`

Verify the bridge exists:

```bash
ip link show vmbr0
```

Update the `BRIDGE` variable in the script if required.

---

## Storage backend

The container root filesystem is created on a Proxmox storage backend.

Default storage:
- `local-lvm`

Verify available storage backends:

```bash
pvesm status
```

Ensure sufficient free space is available.

---

## Required host packages

Required (present on standard Proxmox installs):

- `pct`
- `pveam`
- `bash`
- `curl`

Optional (useful for debugging):

- `jq`
- `iproute2`

---

## GitHub Actions runner documentation

Official GitHub documentation for self-hosted runners:

```
https://docs.github.com/en/actions/concepts/runners/self-hosted-runners
```

This covers runner architecture, security boundaries, lifecycle management, and best practices.

---



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
```

---
## Usage

Run the script on the Proxmox host as root:

```bash
chmod +x github-runner-proxmox.sh
./github-runner-proxmox.sh
```
## Verifying the installation

On the Proxmox host:

```bash
pct exec <CTID> -- systemctl status actions.runner*
```

On GitHub:

```
Repository → Settings → Actions → Runners
```

The runner should appear as **Online** and **Idle**.

---

## Cleanup

```bash
pct stop <CTID>
pct destroy <CTID>
```

Remove the runner from GitHub under:

```
Settings → Actions → Runners
```

---

## Security considerations

- Docker inside a privileged LXC has root-equivalent access
- Treat this runner as trusted infrastructure
- Do not run untrusted workflows on this runner

---

## Notes

- Ubuntu 25.04 is not an LTS release
- Ubuntu 22.04 LTS is recommended for long-term stability
- The script favors clarity and debuggability over brevity

---

## License

Internal use only.
