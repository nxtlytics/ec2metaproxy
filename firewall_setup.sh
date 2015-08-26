#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ -z "$NIC_NAME" ]; then
	echo "NIC_NAME not set."
	exit 1
fi

if [ -z "$PROXY_PORT"]; then
	PROXY_PORT=18000
fi

PROXY_IP=$(ip addr | grep inet | grep ${NIC_NAME} | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
# Drop any traffic to the proxy service that is NOT coming from docker containers
iptables                    \
    -I INPUT                \
    -p tcp                  \
    --dport ${PROXY_PORT}   \
    ! -i docker0            \
    -j DROP

# Redirect any requests from docker containers to the proxy service
iptables                                        \
    -t nat                                      \
    -I PREROUTING                               \
    -p tcp                                      \
    -d 169.254.169.254 --dport 80               \
    -j DNAT                                     \
    --to-destination ${PROXY_IP}:${PROXY_PORT}  \
    -i docker0