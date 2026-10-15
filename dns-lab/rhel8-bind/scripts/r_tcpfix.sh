#!/bin/bash
exec > /tmp/p8r_tcpfix.txt 2>&1
systemctl restart named
sleep 2
ss -lntup | grep ':53' || true
dig @127.0.0.1 www.long90.cn +short
# force IPv4 any listen - show named.conf listen lines
grep listen /etc/named.conf
echo TCPFIX_DONE