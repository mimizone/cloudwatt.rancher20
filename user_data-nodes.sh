#!/bin/bash

# ---------------------------------
# install docker
# ---------------------------------
# rancher doesn't support the latest version of docker with kubernetes at this time. Kubernetes itself recommends Docker 1.12.
# but everything seems to work ok though with Docker 17.06.
#install docker
echo "Installing Docker"
#curl https://releases.rancher.com/install-docker/1.12.sh | sh
apt-get remove -y docker docker-engine docker.io
apt update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
#apt-cache madison docker-ce
apt-get install -y docker-ce=17.06.2~ce-0~ubuntu
usermod -aG docker cloud

# ---------------------------------
# register node to Rancher Manager
# ---------------------------------
RANCHER_MANAGER_IP="192.168.11.3"
RANCHER_SERVER_URL="http://192.168.11.3:8080/v3/scripts/729D159AF286D91802:183142400000:ko0vVM11M2jmP14o"

# using the floating ip is not reliable in my tests. Some of the services in Rancher stay in Initializing state.
# determine the local network IP address that can reach the Rancher Manager and use that instead.
# AGENT_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
AGENT_IP=`ip route get ${RANCHER_MANAGER_IP} | awk 'NR==1 {print $NF}'`

# this command depends on the Rancher Environment.
# double check all the parameters are as expected by the Rancher Manager (especially the Rancher server url)
sudo docker run --rm --privileged \
  -e CATTLE_AGENT_IP="${AGENT_IP}" \
  -e CATTLE_HOST_LABELS='cloud=cloudwatt&tenant=octopus' \
  -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v2.0-alpha4 \
  http://192.168.11.3:8080/v3/scripts/729D159AF286DA918202:1483142400000:ko0vVM11M261K44JRcDYjmP14o#
#--------------------------------
