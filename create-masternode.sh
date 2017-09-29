#!/bin/bash

source "conf.sh"

SECGROUP_NODES_NAME=${RANCHER_SECGROUP_NODES_NAME}
SECGROUP_MANAGER_NAME=${RANCHER_SECGROUP_MANAGER_NAME}
KEYPAIR=${RANCHER_KEYPAIR}
IMAGE="Ubuntu 16.04"
FLAVOR="n1.cw.highmem-4"
USER_DATA="user_data-manager.sh"
VOL_NAME="rancher-manager-db"
VOL_SIZE=${RANCHER_MANAGER_DB_SIZE}
NET_NAME=${RANCHER_NET_NAME}
DEVICE=${RANCHER_MANAGER_DB_DEVICE}

echo '---------------------------------'
echo 'CREATING THE RANCHER MANAGER NODE'
echo '---------------------------------'

# create security groups
echo "creating security groups"
#rancher nodes
SECGROUP_NODES=`openstack security group create -f json ${SECGROUP_NODES_NAME} | jq -r ' map(select(.Field=="id")) | .[].Value' `
#rancher master - allow all ingress/egress to rancher nodes
SECGROUP_MANAGER=`openstack security group create -f json ${SECGROUP_MANAGER_NAME} | jq -r ' map(select(.Field=="id")) | .[].Value' `
openstack security group rule create --egress --remote-group ${SECGROUP_NODES} --protocol udp ${SECGROUP_MANAGER}
openstack security group rule create --egress --remote-group ${SECGROUP_NODES} --protocol tcp ${SECGROUP_MANAGER}
openstack security group rule create --ingress --remote-group ${SECGROUP_NODES} --protocol udp ${SECGROUP_MANAGER}
openstack security group rule create --ingress --remote-group ${SECGROUP_NODES} --protocol tcp ${SECGROUP_MANAGER}
openstack security group rule create --ingress --remote-ip 172.30.0.0/16 --dst-port 8080 --protocol tcp ${SECGROUP_MANAGER}
openstack security group rule create --ingress --remote-ip 192.168.161.0/24 --dst-port 8080 --protocol tcp ${SECGROUP_MANAGER}
openstack security group rule create --ingress --remote-ip 216.38.129.160/27 --dst-port 8080 --protocol tcp ${SECGROUP_MANAGER}


#create a volume
echo "creating volume"
VOL_ID=`openstack volume create -f json ${VOL_NAME} --size ${VOL_SIZE}| jq -r ' map(select(.Field=="id")) | .[].Value' `

# create manager instance with docker installed
echo "creating instance"
INSTANCE=`openstack server create \
-f json \
--image "${IMAGE}" \
--flavor "${FLAVOR}" \
--security-group "default" \
--security-group "${SECGROUP_MANAGER}" \
--security-group "vpn-members" \
--property "role=manager" \
--key-name "${KEYPAIR}" \
--network "${NET_NAME}" \
--user-data "${USER_DATA}" \
--wait \
rancher-manager \
| jq -r ' map(select(.Field=="id")) | .[].Value' `
echo ${INSTANCE}

#attach a volume
echo "attaching volume ${VOL_ID} to ${INSTANCE} as ${DEVICE}"
openstack server add volume --device ${DEVICE} ${INSTANCE} ${VOL_ID}

echo "server boot logs"
echo "openstack console log show rancher-manager"
#openstack console log show rancher-manager

# INSTANCE_IP=`openstack server show ${INSTANCE} -f json | jq -r 'map(select(.Field=="addresses")) | .[].Value' | sed -E "s/.*${NET_NAME}=([0-9\.]*)/\1/"`
#manual steps
#format volume
#mount volume permanently
#start the rancher manager container
#
# echo "configuring the volume ${DEVICE} on ${INSTANCE_IP}"
# ssh-keygen -R ${INSTANCE_IP}
# ssh-keyscan ${INSTANCE_IP}
# ssh cloud@${INSTANCE_IP} -i ${RANCHER_SSH_KEY_PEM} -oStrictHostKeyChecking=no <<'ENDSSH'
# sudo mkfs.ext4 /dev/vdb
# sudo mkdir -p /mnt/rancher-database
# sudo mount /dev/vdb /mnt/database
# echo "/dev/vdb /mnt/rancher-database auto default,nofail 0 3"| sudo tee --append /etc/fstab > /dev/null
# ENDSSH
