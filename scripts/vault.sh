#!/bin/bash
#
# Setup for vault servers

#variables

CONFIG_PATH="/vagrant/configs"

VAULT_CLUSTER_PORT=${VAULT_CLUSTER_PORT:-8201}
VAULT_ENABLE_UI=${VAULT_ENABLE_UI:-true}
VAULT_HOST=${VAULT_HOST:-localhost}
VAULT_LOG_LEVEL=${VAULT_LOG_LEVEL:-info}
VAULT_PORT=${VAULT_PORT:-8200}
VAULT_PROTOCOL=${VAULT_PROTOCOL:-http}

VAULT_ADDRESS="${VAULT_PROTOCOL}://127.0.0.1:${VAULT_PORT}"
VAULT_API_ADDRESS="${VAULT_PROTOCOL}://${VAULT_HOST}:${VAULT_PORT}"
VAULT_CLUSTER_ADDRESS="${VAULT_PROTOCOL}://${VAULT_HOST}:${VAULT_CLUSTER_PORT}"

VAULT_CONFIG="/etc/vault.d/vault.hcl"
VAULT_CREDS="${CONFIG_PATH}/vault.txt"
VAULT_DATA="/opt/vault/data"
VAULT_PROFILE="/etc/profile.d/vault.sh"

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update
sudo apt-get install -y vault
sudo apt-mark hold vault

sudo tee ${VAULT_CONFIG} > /dev/null <<-CONFIG
  ui = ${VAULT_ENABLE_UI}
  log_level = "${VAULT_LOG_LEVEL}"

  storage "file" {
    path = "${VAULT_DATA}"
  }

  listener "tcp" {
    address = "0.0.0.0:${VAULT_PORT}"
    tls_disable = 1
  }
CONFIG

sudo tee ${VAULT_PROFILE} > /dev/null <<-PROFILE
  export VAULT_ADDR=${VAULT_ADDRESS}
PROFILE

sudo systemctl daemon-reload
sudo systemctl start vault
sudo systemctl enable vault

if [[ ! "$(ls -A ${VAULT_DATA})" ]]; then
    sudo VAULT_ADDR=${VAULT_ADDRESS} vault operator init > ${VAULT_CREDS}
fi