#!/usr/bin/env bash
set -euo pipefail

ENABLE_KIBANA_PORT="${ENABLE_KIBANA_PORT:-true}"
ENABLE_AGENT_PORT="${ENABLE_AGENT_PORT:-true}"
INSTALL_DOCKER="${INSTALL_DOCKER:-true}"

log() { echo -e "\n\033[1;32m[+] $1\033[0m"; }
err() { echo -e "\n\033[1;31m[x] $1\033[0m" >&2; exit 1; }

if [[ "${EUID}" -eq 0 ]]; then
  err "Run this script as a standard user with sudo privileges."
fi

sudo -v

log "Updating system packages..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

log "Installing base utilities..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  htop \
  ufw

if [[ "${INSTALL_DOCKER}" == "true" ]]; then
  log "Configuring official Docker repository..."
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-noble}}")"

  cat <<EOF | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable
EOF

  log "Installing Docker..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  sudo systemctl enable --now docker

  if ! id -nG "${USER}" | grep -qw docker; then
    sudo usermod -aG docker "${USER}"
  fi
fi

log "Configuring UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH

if [[ "${ENABLE_KIBANA_PORT}" == "true" ]]; then
  sudo ufw allow 5601/tcp
fi

if [[ "${ENABLE_AGENT_PORT}" == "true" ]]; then
  sudo ufw allow from 10.0.2.0/24 to any port 1514 proto udp
fi

sudo ufw --force enable

log "Environment status:"
ip -4 -br addr show || true
echo ""
sudo ufw status verbose
if [[ "${INSTALL_DOCKER}" == "true" ]]; then
  echo ""
  docker --version
  sudo systemctl is-active docker || true
fi