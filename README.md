# experimenting with Rancher 2.0 on the Cloudwatt openstack public cloud

- Using old school bash scripts and openstack cli client
- creates a rancher master node
- creates the rancher nodes
- optional Openvpn server to create a VPC


## Steps

### check the main configuration file.
adjust as needed. A few other parameters have to be edited directly in the user-data files for instance.
```
cat conf.sh
```

### configure the network, subnet and router
```
./create-network.sh
```

### configure the vpn node.
An OpenVPN server is configured in the instance. In our case, our firewall/router connects to this server with the generated key that shows up in the Openstack console logs.
```
cd vpn
./create-vpn.sh
```

### configure the Rancher server
It creates the instance, installs docker, creates and mounts a volume, start the rancher server using the volume for the mysql database.
If the volume creation doesn't work, and the device is not mounted in the instance, it still starts the rancher server after 1 minute, defaulting to using the local drive of the instance.
```
./create-masternode.sh
```
once the server is up, go to the web interface `http://SERVER_IP:8080`.

Go to the Add host screen.

Go to the Custom provider.

Copy the URL containing the token. You'll need it for the next step.

ex: `http://192.168.11.3:8080/v3/scripts/6923123564E05B347880:1483112300000:zl1bcertyrk0cNtyHqmn5bmE`

### configure the rancher nodes
for this step, you need to edit the `user-data-nodes.sh` file.
The proper URL of the Rancher server has to be set in the variable `RANCHER_SERVER_URL`.
The IP address of the server should also be set in this file in the variable `RANCHER_MANAGER_IP`. It's used to select the right network interface in order to set the rancher agent IP address.

```
./create-instances.sh
```

### tag a node for load balancer role
We want to make sure the ingress traffic to the kubernetes cluster goes through specific nodes. We gonna add a label to a node in Rancher. That label will be used as a selector when creating Ingress/Load Balancer.

`TODO`

### add a floating IP to the ingress node

`TODO`
