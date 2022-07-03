
frontend ${SERVICE_NAME}-http-proxy
    bind :${SERVICE_LOADBALANCER_PORT}
    mode tcp
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }
    default_backend wordpress-http

backend ${SERVICE_NAME}-http
    balance roundrobin
    mode tcp
    option tcplog
    option tcp-check
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100