#!/usr/bin/env bash

BRIDGE=br-int
IFACE_ID=c8c658e7-29f4-425e-96de-f819d09f9431
IFACE_IPV4=10.1.0.8
IFACE_IPV6=fd2a:d02c:d36b:1a::c
IFACE_MAC=fa:16:3e:0f:c8:85
IFACE_NAME=rx-miguel

# Set up the bridge
#sudo ovs-vsctl add-br $BRIDGE -- set Bridge $BRIDGE datapath_type=system protocols="OpenFlow10","OpenFlow13" fail_mode=secure
#sudo ovs-ofctl add-flow $BRIDGE actions=normal

# Set up interface
sudo ip netns add ns-$IFACE_NAME
sudo ip netns exec ns-$IFACE_NAME ip link set lo up
sudo ip netns exec ns-$IFACE_NAME sysctl -w net.ipv6.conf.default.accept_ra=0
IFS=':'
a=($IFACE_MAC)
sudo ovs-vsctl add-port $BRIDGE tap-$IFACE_NAME -- set Interface tap-$IFACE_NAME type=internal external_ids='iface-id'=$IFACE_ID,'iface-status'='active','attached-mac'=${a[0]}'\:'${a[1]}'\:'${a[2]}'\:'${a[3]}'\:'${a[4]}'\:'${a[5]}
sudo ip link set tap-$IFACE_NAME address ${a[0]}':'${a[1]}':'${a[2]}':'${a[3]}':'${a[4]}':'${a[5]}
sudo ip link set tap-$IFACE_NAME netns ns-$IFACE_NAME
sudo ip netns exec ns-$IFACE_NAME ip link set tap-$IFACE_NAME mtu 1450
sudo ip netns exec ns-$IFACE_NAME ip link set tap-$IFACE_NAME up
IFS='.'
a=($IFACE_IPV4)
sudo ip netns exec ns-$IFACE_NAME ip addr add ${a[0]}.${a[1]}.${a[2]}.${a[3]}/24 broadcast ${a[0]}.${a[1]}.${a[2]}.255 dev tap-$IFACE_NAME
sudo ip netns exec ns-$IFACE_NAME ip addr add $IFACE_IPV6/64  dev tap-$IFACE_NAME
sudo ip netns exec ns-$IFACE_NAME ip -4 route replace default via ${a[0]}.${a[1]}.${a[2]}.1 dev tap-$IFACE_NAME
IFS=':'
a=($IFACE_IPV6)
sudo ip netns exec ns-$IFACE_NAME ip -6 route replace default via ${a[0]}:${a[1]}:${a[2]}:${a[3]}::1 dev tap-$IFACE_NAME
#sudo ovs-vsctl set Port tap-tx-miguel tag=1
