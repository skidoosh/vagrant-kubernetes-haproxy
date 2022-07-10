#!/bin/bash
#
# Unseal vault servers after provision or boot

# variables

CONFIG_PATH="/vagrant/configs"

VAULT_PORT=${VAULT_PORT:-8200}
VAULT_PROTOCOL=${VAULT_PROTOCOL:-http}
VAULT_ADDRESS="${VAULT_PROTOCOL}://127.0.0.1:${VAULT_PORT}"
VAULT_CREDS="${CONFIG_PATH}/vault.txt"
VAULT_ROOT_REGEX="(hvs\.[a-zA-Z0-9]{24})$"
VAULT_SEAL_REGEX="Unseal Key [1-5]{1}: ([a-zA-Z0-9+\/]{44})"
VAULT_THRESHOLD_REGEX="threshold of ([0-9]){1}"

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

    for (( i=0; i<${THRESHOLD}; i++ ))
    do
        sudo VAULT_ADDR=${VAULT_ADDRESS} vault operator unseal ${KEYS[i]}
    done
fi