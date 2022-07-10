#!/bin/bash
#
# Setup for Control Plane server

# variables

CONFIG_PATH="/vagrant/configs"

USER_USERNAME="vagrant"
USER_HOME=$(getent passwd "${USER_USERNAME}" | cut -d: -f6)
USER_UID=$(id -u ${USER_USERNAME})
USER_GID=$(id -g ${USER_USERNAME})

sudo kubeadm config images pull

sudo kubeadm init --apiserver-advertise-address=${CONTROLLER_IP} \
                  --apiserver-cert-extra-sans=${CONTROLLER_IP} \
                  --pod-network-cidr=${POD_CIDR} \
                  --node-name $(hostname -s) \
                  --ignore-preflight-errors Swap

if [[ -f "${CONFIG_PATH}/config" ]]; then rm -f ${CONFIG_PATH}/config; fi;
if [[ -f "${CONFIG_PATH}/join.sh" ]]; then rm -f ${CONFIG_PATH}/join.sh; fi;
if [[ ! -d "${CONFIG_PATH}" ]]; then mkdir -p ${CONFIG_PATH}; fi;

cp -i /etc/kubernetes/admin.conf ${CONFIG_PATH}/config
touch ${CONFIG_PATH}/join.sh
chmod +x ${CONFIG_PATH}/join.sh

kubeadm token create --print-join-command > ${CONFIG_PATH}/join.sh

mkdir -p ${USER_HOME}/.kube
sudo cp -i ${CONFIG_PATH}/config ${USER_HOME}/.kube/
sudo chown ${USER_UID}:${USER_GID} ${USER_HOME}/.kube/config

sudo -i -u ${USER_USERNAME} kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml