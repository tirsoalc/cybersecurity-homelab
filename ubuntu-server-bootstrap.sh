#!/usr/bin/env bash
set -euo pipefail

# update packages and upgrade system
sudo apt update && sudo apt upgrade -y

# install basic tools
sudo apt install -y curl wget vim htop net-tools

# install ssh service (if it is not already installed)
sudo apt install -y openssh-server

# set up host-only network interface for isolated connection
# TODO: add network configuration (e.g., netplan or iproute2)

# add docker gpg key
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# add repo to apt source
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

# install docker packages

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
