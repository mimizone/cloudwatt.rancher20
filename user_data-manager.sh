#!/bin/sh

DEVICE="/dev/vdb"

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


# checking the device exists for the next minute
echo "checking device ${DEVICE}"
attempt=1
lsblk ${DEVICE}
exists=$?
while [ $exists != 0 ] && [ $attempt -lt 30 ];
do
  echo "device ${DEVICE} not ready (${attempt})"
  attempt=$((attempt+1))
  sleep 2
  lsblk $finder{DEVICE}
  exist=$?
done

if [ $exists = 0 ];
then
  echo "device ${DEVICE} is available. formating and mounting it"
  mkdir -p /mnt/rancher-database
  mkfs.ext4 ${DEVICE}
  mount ${DEVICE} /mnt/database
  echo "${DEVICE} /mnt/rancher-database auto default,nofail 0 3"| sudo tee --append /etc/fstab > /dev/null

  #start the rancher manager
  echo "starting the rancher server container with dedicated volume for the database"
  docker run -d -v /mnt/rancher-database:/var/lib/mysql --restart=unless-stopped -p 8080:8080 rancher/server:preview
else
  echo "no device ${DEVICE} available"
  echo "starting the rancher server container with local storage"
  docker run -d --restart=unless-stopped -p 8080:8080 rancher/server:preview
fi
