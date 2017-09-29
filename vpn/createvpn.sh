#!/bin/bash

source "../conf.sh"

VPN_PRIVATE_IP=${RANCHER_VPN_PRIVATE_IP}
IMAGE="Ubuntu 12.04"
FLAVOR="t1.cw.tiny"
NET_ID=`openstack network show ${RANCHER_NET_NAME} -f json | jq -r ' map(select(.Field=="id")) | .[].Value' `
KEYPAIR=${RANCHER_KEYPAIR}
SUBNET_NAME=${RANCHER_SUBNET_NAME}
GATEWAY=${RANCHER_GATEWAY}
SECGROUP_MEMBERS_NAME="vpn-members"
SECGROUP_NAME="vpn"

echo "Creating security groups"
echo "------------------------"
#vpn members
VPN_SECGROUP_NODES=`openstack security group show ${SECGROUP_MEMBERS_NAME} -f json | jq -r ' map(select(.Field=="id")) | .[].Value' `
if [ -z ${VPN_SECGROUP_NODES} ];
then
  echo "creating security group ${SECGROUP_MEMBERS_NAME}"
  VPN_SECGROUP_NODES=`openstack security group create -f json ${SECGROUP_MEMBERS_NAME} | jq -r ' map(select(.Field=="id")) | .[].Value' `
fi
#vpn
echo "creating security group ${SECGROUP_NAME}"
VPN_SECGROUP=`openstack security group create -f json ${SECGROUP_NAME} | jq -r ' map(select(.Field=="id")) | .[].Value' `
openstack security group rule create --ingress --remote-ip 0.0.0.0/0 --dst-port 22 --protocol tcp ${VPN_SECGROUP}
openstack security group rule create --ingress --remote-ip 0.0.0.0/0 --dst-port 1194 --protocol udp ${VPN_SECGROUP}
openstack security group rule create --egress --remote-group ${VPN_SECGROUP_NODES} --protocol udp ${VPN_SECGROUP}
openstack security group rule create --egress --remote-group ${VPN_SECGROUP_NODES} --protocol tcp ${VPN_SECGROUP}
openstack security group rule create --ingress --remote-group ${VPN_SECGROUP_NODES} --protocol udp ${VPN_SECGROUP}
openstack security group rule create --ingress --remote-group ${VPN_SECGROUP_NODES} --protocol tcp ${VPN_SECGROUP}
# TODO remove default egress all and limit to VPN remote endpoint



echo "Adding static routes in the subnet ${SUBNET_NAME}"
echo "------------------------"
SUBNET_ID=`openstack subnet show ${SUBNET_NAME} -f json | jq -r ' map(select(.Field=="id")) | .[].Value' `
openstack subnet set --host-route destination=192.168.161.0/24,gateway=${VPN_PRIVATE_IP} ${SUBNET_ID}
openstack subnet set --host-route destination=172.30.0.0/16,gateway=${VPN_PRIVATE_IP} ${SUBNET_ID}
openstack subnet set --host-route destination=0.0.0.0/0,gateway=${GATEWAY} ${SUBNET_ID}


echo "Creating vpn instance"
echo "------------------------"
openstack server create \
--key-name "${KEYPAIR}" \
--security-group ${SECGROUP_NAME} \
--flavor "${FLAVOR}" \
--image "${IMAGE}" \
--nic net-id=${NET_ID},v4-fixed-ip=${VPN_PRIVATE_IP} \
--user-data "userdata.sh" \
vpn

echo "Adding floating IP"
echo "------------------------"
INSTANCEID=`openstack server show vpn -f json | jq -r ' map(select(.Field == "id")) | .[].Value'`
IP=`openstack floating ip list -f json | jq -r 'map(select(.Port==null)) | .[0]."Floating IP Address"'`
if [ ${IP} = null ];
then
  echo "creating new IP"
  IP=`openstack floating ip create public -f json | \
  jq -r 'map(select(.Field == "floating_ip_address")) | .[].Value'`
fi
openstack server add floating ip ${INSTANCEID} ${IP}
echo "Floating IP: ${IP}"
