#!/bin/bash

IMAGE="Ubuntu 12.04"
FLAVOR="t1.cw.tiny"
NET_ID="900189f9-09ec-4cc2-8738-9108be704736"
KEYPAIR="bigk8s"
SEC_GROUP_RANCHER_NODES="rancher-nodes"
VPN_PRIVATE_IP="192.168.11.254"
GATEWAY="192.168.11.1"
SUBNET_NAME="bitpusher-subnet"

echo "Creating security groups"
echo "------------------------"
SECGROUP=`openstack security group create -f json vpn | jq -r ' map(select(.Field=="id")) | .[].Value' `
SECGROUP_RANCHER=`openstack security group show -f json ${SEC_GROUP_RANCHER_NODES} | jq -r ' map(select(.Field=="id")) | .[].Value' `
openstack security group rule create --ingress --remote-ip 0.0.0.0/0 --dst-port 22 --protocol tcp ${SECGROUP}
openstack security group rule create --ingress --remote-ip 0.0.0.0/0 --dst-port 1194 --protocol udp ${SECGROUP}
openstack security group rule create --egress --remote-group ${SECGROUP_RANCHER} --protocol udp ${SECGROUP}
openstack security group rule create --egress --remote-group ${SECGROUP_RANCHER} --protocol tcp ${SECGROUP}
openstack security group rule create --ingress --remote-group ${SECGROUP_RANCHER} --protocol udp ${SECGROUP}
openstack security group rule create --ingress --remote-group ${SECGROUP_RANCHER} --protocol tcp ${SECGROUP}
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
--security-group vpn \
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
