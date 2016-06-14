#!/usr/bin/env bash

# Script Arguments:
# $1 -  Interface for Vlan type networks
# $2 -  Physical network for Vlan type networks interface
VLAN_INTERFACE=$1
PHYSICAL_NETWORK=$2

cp /vagrant/provisioning/local.conf.base devstack/local.conf

# Get the IP address
ipaddress=$(ip -4 addr show eth1 | grep -oP "(?<=inet ).*(?=/)")

# Create bridges for Vlan type networks
sudo ifconfig $VLAN_INTERFACE 0.0.0.0 up
bridge=br-$VLAN_INTERFACE
sudo ovs-vsctl add-br $bridge
sudo ovs-vsctl add-port $bridge $VLAN_INTERFACE

# Adjust local.conf
cat << DEVSTACKEOF >> devstack/local.conf

# Set this host's IP
HOST_IP=$ipaddress

# Enable Neutron as the networking service
disable_service n-net
enable_service neutron
enable_service q-svc
enable_service q-meta
enable_service q-agt
enable_service q-dhcp
enable_service q-l3

[[post-config|\$NEUTRON_CONF]]
[DEFAULT]
service_plugins=router,segments

[[post-config|/\$Q_PLUGIN_CONF_FILE]]
[ml2]
type_drivers=flat,vlan,vxlan
tenant_network_types=vxlan,vlan
mechanism_drivers=openvswitch,l2population
extension_drivers=port_security

[ml2_type_vxlan]
vni_ranges=1000:1999

[ml2_type_vlan]
network_vlan_ranges=$PHYSICAL_NETWORK:1000:1999

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
DEVSTACKEOF

devstack/stack.sh
