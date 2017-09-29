#!/usr/local/bin/bash

ADD_FLOATING_IP=false
CREATE_INSTANCE=true

ARG_NB_INSTANCE=2
SSH_KEY="~/.ssh/octopus-admin.pem"
ARG_KEYPAIR="octopus-admin"
ARG_IMAGE="Ubuntu 16.04"
#SSH_USER="cloud"
# ARG_FLAVOR="n1.cw.highmem-4"
ARG_FLAVOR="n1.cw.standard-4"
ARG_SECGROUP="rancher-nodes"
ARG_NET="bitpusher"
ARG_USER_DATA="user_data-nodes.sh"

# --------------------------

if [ "${CREATE_INSTANCE}" = true ];
then
echo "creating ${ARG_NB_INSTANCE} instances"
openstack server create \
-f table \
--image "${ARG_IMAGE}" \
--flavor "${ARG_FLAVOR}" \
--security-group "default" \
--security-group "${ARG_SECGROUP}" \
--security-group "vpn-members" \
--property role=moo \
--key-name "${ARG_KEYPAIR}" \
--network "${ARG_NET}" \
--min 1 \
--max ${ARG_NB_INSTANCE} \
--user-data ${ARG_USER_DATA} \
--wait \
moo

fi
# --------------------------


echo "listing instances"
INSTANCES=`openstack server list --long -f json | \
jq -r "map(select(.Properties | contains(\"'moo'\") )) | .[].ID"`
echo "${INSTANCES}"


# --------------------------------------
# ADD FLOATING IPs
# --------------------------------------
if [ "${ADD_FLOATING_IP}" = true ];
then

# requires bash 4
declare -A INSTANCE_TO_IP

for INSTANCE in $INSTANCES;
do
  #TODO check the instance doesn't have a floating yet
  IP=`openstack floating ip list -f json | jq -r 'map(select(.Port==null)) | .[0]."Floating IP Address"'`
  if [ ${IP} = null ];
  then
    echo "creating new IP"
    IP=`openstack floating ip create public -f json | \
    jq -r 'map(select(.Field == "floating_ip_address")) | .[].Value'`
  fi
  echo "add IP ${IP} to instance ${INSTANCE}"
  openstack server add floating ip ${INSTANCE} ${IP}
  INSTANCE_TO_IP+=( ["${INSTANCE}"]="${IP}" )
  #cleanup local SSH configuration
  ssh-keygen -R ${IP}
done

# need to wait for ssh to be started
echo "sleeping 20s"
sleep 20

# clean up local ssh client configuration
for INSTANCE in ${!INSTANCE_TO_IP[@]};
do
   echo "cleanup local SSH config for host ${INSTANCE_TO_IP[$INSTANCE]}"
   ssh-keygen -R ${INSTANCE_TO_IP[$INSTANCE]}
   ssh-keyscan -H ${INSTANCE_TO_IP[$INSTANCE]} >> ~/.ssh/known_hosts
#   ssh -t -oStrictHostKeyChecking=no -i ${SSH_KEY} -l "${SSH_USER}" -i ${SSH_KEY} ${INSTANCE_TO_IP[$INSTANCE]} "screen -dm ${DOCKER_INSTALLER}" &
done

fi
# end adding floating IP
# --------------------------------------
