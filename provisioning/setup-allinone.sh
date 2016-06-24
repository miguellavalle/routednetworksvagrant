#!/usr/bin/env bash

# Script Arguments:
# $1 -  Interface for Vlan type networks
# $2 -  Physical network for Vlan type networks interface
VLAN_INTERFACE=$1
PHYSICAL_NETWORK=$2
COMPUTES_PHYSICAL_NETWORK=$3

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
network_vlan_ranges=$PHYSICAL_NETWORK:1000:1999,$COMPUTES_PHYSICAL_NETWORK:1000:1999

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

[[post-config|\$KEYSTONE_CONF]]
[token]
expiration=30000000
DEVSTACKEOF

devstack/stack.sh

source devstack/openrc admin admin

SEGMENTATION_ID=2016
NET_ID=$(neutron net-create multinet --shared --segments type=dict list=true \
    provider:physical_network=physnet1,provider:segmentation_id=$SEGMENTATION_ID,provider:network_type=vlan \
    provider:physical_network=physnet2,provider:segmentation_id=$SEGMENTATION_ID,provider:network_type=vlan |
    grep ' id ' |
    awk 'BEGIN{} {print $4} END{}')

TOKEN=$(curl -s -X POST http://localhost:5000/v2.0/tokens \
    -H "Content-type: application/json" \
    -d '
        {"auth": {
             "passwordCredentials": {
                 "username":"admin",
                 "password":"devstack"
             },
             "tenantName":"admin"
         }
        }' \
    | jq -r .access.token.id)

SEGMENT1_ID=$(curl -s -X GET http://localhost:9696/v2.0/segments?physical_network=physnet1\&network_id=$NET_ID \
    -H "Content-type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    | jq -r .segments[0].id)

SEGMENT2_ID=$(curl -s -X GET http://localhost:9696/v2.0/segments?physical_network=physnet2\&network_id=$NET_ID \
    -H "Content-type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    | jq -r .segments[0].id)

neutron subnet-create --ip_version 4 --name multinet-segmen1-subnet $NET_ID 10.0.1.0/24 --segment_id $SEGMENT1_ID
neutron subnet-create --ip_version 6 --name ipv6-multinet-segmen1-subnet $NET_ID fd2a:d02c:d36b:1a::/64 --segment_id $SEGMENT1_ID
neutron subnet-create --ip_version 4 --name multinet-segmen2-subnet $NET_ID 10.0.2.0/24 --segment_id $SEGMENT2_ID
neutron subnet-create --ip_version 6 --name ipv6-multinet-segmen2-subnet $NET_ID fd2a:d02c:d36b:1b::/64 --segment_id $SEGMENT2_ID
