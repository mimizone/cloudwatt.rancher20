#!/bin/bash

source "conf.sh"

NET_NAME=${RANCHER_NET_NAME}
SUBNET_NAME=${RANCHER_SUBNET_NAME}
NET_PUBLIC_NAME=${RANCHER_NET_PUBLIC_NAME}
GATEWAY=${RANCHER_GATEWAY}
SUBNET_RANGE=${RANCHER_CIDR}
DHCP_MIN=${RANCHER_DHCP_MIN}
DHCP_MAX=${RANCHER_DHCP_MAX}


# create network
echo "creating network ${NET_NAME}"
NET_ID=`openstack network create ${NET_NAME} -f json |\
  jq -r ' map(select(.Field=="id")) | .[].Value'`

#create subnet
echo "creating subnet ${SUBNET_NAME}"
SUBNET_ID=`openstack subnet create -f json \
--dhcp \
--gateway ${GATEWAY} \
--subnet-range ${SUBNET_RANGE} \
--allocation-pool start=${DHCP_MIN},end=${DHCP_MAX} \
--network ${NET_ID} \
${SUBNET_NAME} |\
 jq -r ' map(select(.Field=="id")) | .[].Value'`

# create router
echo "creating router"
NET_PUBLIC_ID=`openstack network show ${NET_PUBLIC_NAME} -f json |  jq -r ' map(select(.Field=="id")) | .[].Value'`
openstack router create router
openstack router set router --external-gateway ${NET_PUBLIC_ID}
openstack router add subnet router ${SUBNET_ID}
