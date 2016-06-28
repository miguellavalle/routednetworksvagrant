#!/bin/sh

# Script Arguments:
# $1 -  Vlan ID for the segments to route
VLAN_ID=$1
ETH2_IPV4_ADDR=$2
ETH3_IPV4_ADDR=$3
ETH2_IPV6_ADDR=$4
ETH3_IPV6_ADDR=$5
IPV4_PREFIXLEN=$6
IPV6_PREFIXLEN=$7

sudo modprobe 8021q
sudo vconfig add eth2 $VLAN_ID
sudo vconfig add eth3 $VLAN_ID

sudo ifconfig eth2 0.0.0.0 up
sudo ifconfig eth2.$VLAN_ID $ETH2_IPV4_ADDR/$IPV4_PREFIXLEN up
sudo ifconfig eth2.$VLAN_ID inet6 add $ETH2_IPV6_ADDR/$IPV6_PREFIXLEN

sudo ifconfig eth3 0.0.0.0 up
sudo ifconfig eth3.$VLAN_ID $ETH3_IPV4_ADDR/$IPV4_PREFIXLEN up
sudo ifconfig eth3.$VLAN_ID inet6 add $ETH3_IPV6_ADDR/$IPV6_PREFIXLEN

sudo iptables -t nat -A POSTROUTING -o eth2.$VLAN_ID -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -o eth3.$VLAN_ID -j MASQUERADE
sudo ip6tables -t nat -A POSTROUTING -o eth2.$VLAN_ID -j MASQUERADE
sudo ip6tables -t nat -A POSTROUTING -o eth3.$VLAN_ID -j MASQUERADE
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo bash -c 'echo 1 > /proc/sys/net/ipv6/conf/all/forwarding'
