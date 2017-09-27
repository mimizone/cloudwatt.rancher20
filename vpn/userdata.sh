#!/bin/bash


#################################
#
# User Data configuring OpenVPN and routing
#
#################################

apt-get update
apt-get install -y openvpn

openvpn --genkey --secret /etc/openvpn/static.key
echo "OPENVPN GENERATED STATIC KEY"
cat /etc/openvpn/static.key

cat >/etc/openvpn/s2s-octopus.conf <<EOF
dev tun
ifconfig 172.30.254.93 172.30.254.94
route 192.168.161.0 255.255.255.0
route 172.30.0.0. 255.255.0.0
secret static.key
cipher AES-128-CBC
auth SHA1
proto udp
keepalive 10 60
ping-timer-rem
persist-tun
persist-key
verb 4
EOF
service openvpn restart



# enable IP_FORWARDING
sed -ir 's/#*net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p
