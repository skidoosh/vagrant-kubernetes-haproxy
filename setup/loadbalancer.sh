#!/bin/bash
#
# Setup haproxy

kubectl get svc -o wide | while read SERVICE; do
    if [[ "${SERVICE}" =~ "NodePort" ]]; then
        SERVICE_LOADBALANCER_PORT="$(( $RANDOM % 8000 + 10000 ))"
        [[ "${SERVICE}" =~ ([0-9]+):([0-9]+)\/TCP ]] && SERVICE_PORT="${BASH_REMATCH[2]}"
        [[ "${SERVICE}" =~ ^([a-zA-Z0-9]+) ]] && SERVICE_NAME="${BASH_REMATCH[1]}"
    fi
done