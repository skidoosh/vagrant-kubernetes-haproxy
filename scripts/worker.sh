#!/bin/bash
#
# Setup for worker node servers

# variables

CONFIG_PATH="/vagrant/configs"

USER_USERNAME="vagrant"
USER_HOME=$(getent passwd "${USER_USERNAME}" | cut -d: -f6)
USER_UID=$(id -u ${USER_USERNAME})
USER_GID=$(id -g ${USER_USERNAME})

/bin/bash ${CONFIG_PATH}/join.sh -v

mkdir -p ${USER_HOME}/.kube
sudo cp -i ${CONFIG_PATH}/config ${USER_HOME}/.kube/
sudo chown ${USER_UID}:${USER_GID} ${USER_HOME}/.kube/config
sudo -i -u ${USER_USERNAME} kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker