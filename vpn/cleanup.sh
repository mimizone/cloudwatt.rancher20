#!/bin/bash

source "../conf.sh"

VPN_PRIVATE_IP=${RANCHER_VPN_PRIVATE_IP}
SUBNET_ID=`openstack subnet show ${RANCHER_SUBNET_NAME} -f json | jq -r ' map(select(.Field=="id")) | .[].Value' `

openstack server delete vpn
openstack security group delete vpn
openstack security group delete vpn-members

openstack subnet unset --host-route destination=192.168.161.0/24,gateway=${VPN_PRIVATE_IP} ${SUBNET_ID}
openstack subnet unset --host-route destination=172.30.0.0/16,gateway=${VPN_PRIVATE_IP} ${SUBNET_ID}
