#!/bin/bash
#
# Setup haproxy/rebuild haproxy config
# Not too smart yet. Presumes one service 
# instance on each node

SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
TEMPLATES="${SCRIPTPATH}/../templates"
CONFIGS="${SCRIPTPATH}/../configs"

cat ${TEMPLATES}/haproxy.cfg.tpl > ${CONFIGS}/haproxy.cfg
cat ${TEMPLATES}/haproxy_node.cfg.tpl >> ${CONFIGS}/haproxy.cfg

NODES=$(kubectl get no -o wide)
SERVICES=$(kubectl get svc -o wide)

echo "${NODES}" | while read NODE; do
    if [[ "${NODE}" =~ ^worker\-[1-9]+ ]]; then
        [[ "${NODE}" =~ ^([a-zA-Z0-9]+) ]] && NODE_NAME="${BASH_REMATCH[1]}"
        [[ "${NODE}" =~ ^worker\-([1-9])+ ]] && NODE_WORKER="${BASH_REMATCH[1]}" 
        [[ "${NODE}" =~ ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}) ]] && NODE_IP="${BASH_REMATCH[1]}"

        TEMPLATE=$(cat ${TEMPLATES}/haproxy_node_fragment.cfg.tpl)
        eval "echo \"    ${TEMPLATE}\"" >> ${CONFIGS}/haproxy.cfg
    fi
done

echo "${SERVICES}" | while read SERVICE; do
    if [[ "${SERVICE}" =~ "NodePort" ]]; then
        SERVICE_LOADBALANCER_PORT="$(shuf -i 8000-10000 -n 1)"
        [[ "${SERVICE}" =~ ^([a-zA-Z0-9]+) ]] && SERVICE_NAME="${BASH_REMATCH[1]}"
        [[ "${SERVICE}" =~ ([0-9]+):([0-9]+)\/TCP ]] && SERVICE_PORT="${BASH_REMATCH[2]}"

        TEMPLATE=$(cat ${TEMPLATES}/haproxy_service.cfg.tpl)
        eval "echo \"${TEMPLATE}\"" >> ${CONFIGS}/haproxy.cfg

        echo "${NODES}" | while read NODE; do
            if [[ "${NODE}" =~ ^worker\-[1-9]+ ]]; then
                [[ "${NODE}" =~ ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}) ]] && SERVICE_IP="${BASH_REMATCH[1]}"
                [[ "${NODE}" =~ ^worker\-([1-9])+ ]] && SERVICE_WORKER="${BASH_REMATCH[1]}" 
                TEMPLATE=$(cat ${TEMPLATES}/haproxy_service_fragment.cfg.tpl)
                eval "echo \"    ${TEMPLATE}\"" >> ${CONFIGS}/haproxy.cfg
            fi
        done
    fi
done

vagrant ssh loadbalancer --command="sudo cp /vagrant/configs/haproxy.cfg /etc/haproxy/haproxy.cfg && sudo systemctl restart haproxy"