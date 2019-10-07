#!/usr/bin/env bash

# Script Arguments:
# $1 -  Allinone node IP adddress
# $2 -  Interface for Vlan type networks
# $3 -  Physical network for Vlan type networks interface
ALLINONE_IP=$1
VLAN_INTERFACE=$2
PHYSICAL_NETWORK=$3

cp /vagrant/provisioning/local.conf.base devstack/local.conf

# Get the IP address
ipaddress=$(ip -4 addr show eth1 | grep -oP "(?<=inet ).*(?=/)")

# Create bridge for Vlan type networks
sudo ifconfig $VLAN_INTERFACE 0.0.0.0 up
bridge=br-$VLAN_INTERFACE
sudo ovs-vsctl add-br $bridge
sudo ovs-vsctl add-port $bridge $VLAN_INTERFACE

# Adjust some things in local.conf
cat << DEVSTACKEOF >> devstack/local.conf

# Set this host's IP
HOST_IP=$ipaddress

# Enable services to be executed in compute node
ENABLED_SERVICES=n-cpu,neutron,n-novnc,q-agt,q-dhcp,q-l3,q-meta,placement-client

# Set the controller's IP
SERVICE_HOST=$ALLINONE_IP
MYSQL_HOST=$ALLINONE_IP
RABBIT_HOST=$ALLINONE_IP
Q_HOST=$ALLINONE_IP
GLANCE_HOSTPORT=$ALLINONE_IP:9292
VNCSERVER_PROXYCLIENT_ADDRESS=$ipaddress
VNCSERVER_LISTEN=0.0.0.0

[[post-config|/\$Q_PLUGIN_CONF_FILE]]
[ovs]
local_ip=$ipaddress
bridge_mappings=$PHYSICAL_NETWORK:$bridge

[agent]
tunnel_types=vxlan
l2_population=True

[[post-config|\$Q_L3_CONF_FILE]]
[DEFAULT]
router_delete_namespaces=True

[[post-config|\$Q_DHCP_CONF_FILE]]
[DEFAULT]
dhcp_delete_namespaces=True
enable_isolated_metadata=True
DEVSTACKEOF

devstack/stack.sh
