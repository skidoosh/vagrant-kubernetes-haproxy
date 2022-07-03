#!/bin/bash
#
# Setup for vault servers

set -euxo pipefail

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
VAULT_CREDS="/vagrant/configs/vault.txt"
VAULT_DATA="/opt/vault/data"
VAULT_PROFILE="/etc/profile.d/vault.sh"

VAULT_ROOT_REGEX="(hvs\.[a-zA-Z0-9]{24})$"
VAULT_SEAL_REGEX="Unseal Key [1-5]{1}: ([a-zA-Z0-9+\/]{44})"
VAULT_THRESHOLD_REGEX="threshold of ([0-9]){1}"

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y vault
sudo apt-mark hold vault

sudo tee ${VAULT_CONFIG} > /dev/null <<-CONFIG
  ui = ${VAULT_ENABLE_UI}
  api_addr = "${VAULT_API_ADDRESS}"
  cluster_addr = "${VAULT_CLUSTER_ADDRESS}"
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

if [ "$(sudo VAULT_ADDR=${VAULT_ADDRESS} vault status | tr -d '\011\012\013\014\015\040' | grep -c 'Sealedtrue')" -gt 0 ]; then
    declare KEYS=()
    ROOT=""
    THRESHOLD=0

    while read l
    do
        if [[ $l =~ ${VAULT_SEAL_REGEX} ]]; then
            KEYS+=(${BASH_REMATCH[1]})
        fi

        if [[ $l =~ ${VAULT_ROOT_REGEX} ]]; then
            ROOT=${BASH_REMATCH[0]}
        fi

        if [[ $l =~ ${VAULT_THRESHOLD_REGEX} ]]; then
            THRESHOLD=${BASH_REMATCH[1]}
        fi
    done < ${VAULT_CREDS}

    for (( i=0; i<${threshold}; i++ ))
    do
        sudo VAULT_ADDR=${VAULT_ADDRESS} vault operator unseal ${keys[i]}
    done
fi