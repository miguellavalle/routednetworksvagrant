#!/usr/bin/env bash

# Script Arguments:
# $1 -  Interface for Vlan type networks
# $2 -  Physical network for Vlan type networks interface in allinone and compute1 "rack"
# $3 -  Physical network for Vlan type networks interface in compute2 and compute3 "rack"
# $4 -  Segmentation id to be used when creating vlan segments
# $5 -  IPv4 subnet CIDR for vlan's segment 1
# $6 -  IPv4 subnet CIDR for vlan's segment 2
# $7 -  IPv6 subnet CIDR for vlan's segment 1
# $8 -  IPv6 subnet CIDR for vlan's segment 2
VLAN_INTERFACE=$1
PHYSICAL_NETWORK=$2
COMPUTES_PHYSICAL_NETWORK=$3
SEGMENTATION_ID=$4
SEGMENT1_IPV4_CIDR=$5
SEGMENT2_IPV4_CIDR=$6
SEGMENT1_IPV6_CIDR=$7
SEGMENT2_IPV6_CIDR=$8

cp /vagrant/provisioning/local.conf.base devstack/local.conf

# Get the IP address
ipaddress=$(ip -4 addr show enp0s8 | grep -oP "(?<=inet ).*(?=/)")

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
enable_service placement-api
enable_service neutron
enable_service neutron-api
#enable_service q-svc
enable_service q-meta
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service tempest

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
enable_isolated_metadata=True

[[post-config|\$KEYSTONE_CONF]]
[token]
expiration=30000000
DEVSTACKEOF

devstack/stack.sh

source devstack/openrc admin admin

NET_ID=$(openstack network create --share --provider-physical-network physnet1 \
    --provider-network-type vlan --provider-segment $SEGMENTATION_ID multinet |
    grep ' id ' | awk 'BEGIN{} {print $4} END{}')

openstack network segment create --physical-network physnet2 \
    --network-type vlan --segment $SEGMENTATION_ID --network $NET_ID segment2
#NET_ID=$(neutron net-create multinet --shared --segments type=dict list=true \
#    provider:physical_network=physnet1,provider:segmentation_id=$SEGMENTATION_ID,provider:network_type=vlan \
#    provider:physical_network=physnet2,provider:segmentation_id=$SEGMENTATION_ID,provider:network_type=vlan |
#    grep ' id ' |
#    awk 'BEGIN{} {print $4} END{}')

TOKEN=$(curl -si -X POST http://localhost/identity/v3/auth/tokens \
    -H "Content-type: application/json" \
    -d @/vagrant/utils/token-request.json | awk '/X-Subject-Token/ {print $2}')

SEGMENT1_ID=$(curl -s -X GET http://localhost:9696/v2.0/segments?physical_network=physnet1\&network_id=$NET_ID \
    -H "Content-type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    | jq -r .segments[0].id)

SEGMENT2_ID=$(curl -s -X GET http://localhost:9696/v2.0/segments?physical_network=physnet2\&network_id=$NET_ID \
    -H "Content-type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    | jq -r .segments[0].id)

openstack network segment set --name segment1 $SEGMENT1_ID

openstack subnet create --network $NET_ID --network-segment $SEGMENT1_ID \
    --ip-version 4 --subnet-range $SEGMENT1_IPV4_CIDR multinet-segment1-subnet 
#neutron subnet-create --ip_version 4 --name multinet-segment1-subnet $NET_ID \
#    $SEGMENT1_IPV4_CIDR --segment_id $SEGMENT1_ID
openstack subnet create --network $NET_ID --network-segment $SEGMENT1_ID \
    --ip-version 6 --subnet-range $SEGMENT1_IPV6_CIDR ipv6-multinet-segment1-subnet
#neutron subnet-create --ip_version 6 --name ipv6-multinet-segment1-subnet $NET_ID \
#    $SEGMENT1_IPV6_CIDR --segment_id $SEGMENT1_ID
openstack subnet create --network $NET_ID --network-segment $SEGMENT2_ID \
    --ip-version 4 --subnet-range $SEGMENT2_IPV4_CIDR multinet-segment2-subnet 
#neutron subnet-create --ip_version 4 --name multinet-segment2-subnet $NET_ID \
#    $SEGMENT2_IPV4_CIDR --segment_id $SEGMENT2_ID
openstack subnet create --network $NET_ID --network-segment $SEGMENT2_ID \
    --ip-version 6 --subnet-range $SEGMENT2_IPV6_CIDR ipv6-multinet-segment2-subnet
#neutron subnet-create --ip_version 6 --name ipv6-multinet-segment2-subnet $NET_ID \
#    $SEGMENT2_IPV6_CIDR --segment_id $SEGMENT2_ID
