#!/bin/bash
#
# Setup for worker node loadbalancer

# variables

NODES=""

sudo apt-get install -y haproxy
sudo apt-mark hold haproxy

for i in $(seq 1 $NUM_WORKER_NODES); do
    NODES+="server node_${i} $IP_KUBE_WORKERS$((IP_START + i)):10250 check check-ssl verify none
    "
done

cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig

cat > /etc/haproxy/haproxy.cfg <<EOD
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA->
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

listen stats
    bind    *:9000
    mode    http
    stats   enable
    stats   hide-version
    stats   uri       /stats
    stats   refresh   30s
    stats   realm     Haproxy\ Statistics
    stats   auth      Admin:Password

frontend k8s-node-https-proxy
    bind :443
    mode tcp
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }
    default_backend k8s-node-https

backend k8s-node-https
    balance roundrobin
    mode tcp
    option tcplog
    option tcp-check
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    ${NODES}
EOD

sudo systemctl restart haproxy
