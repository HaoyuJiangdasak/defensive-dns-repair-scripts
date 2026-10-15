#!/bin/bash
exec > /tmp/p8_s02.txt 2>&1
hostname
ip -4 addr
rpm -qa | grep -E '^bind' || true
cp -a /etc/named.conf /etc/named.conf.bak.$(date +%Y%m%d%H%M%S) || true
cp /tmp/p8/named_fwd.conf /etc/named.conf
chgrp named /etc/named.conf || true
named-checkconf; echo checkconf_rc=$?
# avoid firewalld hang
pkill -f firewall-cmd || true
systemctl stop firewalld || true
systemctl disable firewalld || true
systemctl enable named
systemctl restart named
sleep 2
systemctl is-active named
ss -lntup | grep 53 || true
echo '=== dig via local forwarder ==='
dig @127.0.0.1 www.long90.cn A +noall +answer
dig @192.168.72.12 www.long90.cn A +noall +answer
dig @192.168.72.12 long90.cn MX +noall +answer
dig @192.168.72.12 dns.long90.cn A +noall +answer
dig @192.168.72.12 web.long90.cn +noall +answer
echo S02_DONE