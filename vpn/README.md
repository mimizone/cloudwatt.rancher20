# creates an OpenVPN server with a static key, for a site-to-site tunnel

The generated key is available in `/etc/openvpn/static.key`.
It's also in the openstack logs of the instance.

Modify the createvpn.sh file with your own:
- local IP address of the VPN server instance
- the IP of the gateway on the subnet
- security group name of the rancher nodes
- Network id and subnet name
- keypair
- custom IP routes (in the subnet configuration)


Modify the user_data.sh file with your own:
- local and remote IP address for the tunnel
- custom routes
