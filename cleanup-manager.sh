#!/bin/bash

openstack server delete rancher-manager
openstack volume delete rancher-manager-db
openstack security group delete rancher-manager
openstack security group delete rancher-nodes
