#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

function get_default_interface() {
    echo $(ip route | sed -n 's/default via .* dev \(eth.\) .*$/\1/p')
}

function get_ip_from_interface() {
    local INTERFACE=$1
    echo $(ip -4 addr show dev ${INTERFACE} primary | grep inet | awk '{split($2,a,"/"); print a[1]}')
}

function setup_iptables() {
    echo "Dropping traffic to ${PROXY_PORT:-18000} not from interface docker0..."
    iptables                            \
        -I INPUT                        \
        -p tcp                          \
        --dport ${PROXY_PORT:-18000}    \
        ! -i docker0                    \
        -j DROP

    echo "Redirect any requests from docker containers to the proxy service..."
    iptables                                                \
        -t nat                                              \
        -I PREROUTING                                       \
        -p tcp                                              \
        -d 169.254.169.254 --dport 80                       \
        -j DNAT                                             \
        --to-destination ${PROXY_IP}:${PROXY_PORT:-18000}   \
        -i docker0
}

DEFAULT_INTERFACE=$(get_default_interface)
PROXY_IP=$(get_ip_from_interface ${DEFAULT_INTERFACE})

setup_iptables
