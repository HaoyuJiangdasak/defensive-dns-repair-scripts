#!/bin/bash
exec > /tmp/p8_fix.txt 2>&1
# kill hung firewall-cmd
pkill -f firewall-cmd || true
systemctl stop firewalld || true
systemctl disable firewalld || true
# ensure newlines on zones
echo >> /var/named/long90.cn.zone
echo >> /var/named/72.168.192.zone
systemctl enable named
systemctl restart named
sleep 2
systemctl is-active named
ss -lntup | grep 53 || true
# allow DNS without firewalld (firewalld stopped)
dig @127.0.0.1 dns.long90.cn A +short
dig @192.168.72.11 dns.long90.cn A +short
dig @192.168.72.11 www.long90.cn A +short
dig @192.168.72.11 web.long90.cn +short
dig @192.168.72.11 -x 192.168.72.11 +short
dig @192.168.72.11 long90.cn NS +short
dig @192.168.72.11 long90.cn MX +short
dig @192.168.72.11 slave.long90.cn A +short
dig @192.168.72.11 ftp.long90.cn A +short
dig @192.168.72.11 -x 192.168.72.14 +short
host 192.168.72.13 192.168.72.11
echo FIX_DONE
# Also restart firewalld later with dns service non-blocking
systemctl start firewalld || true
firewall-cmd --permanent --add-service=dns || true
firewall-cmd --reload || true
systemctl is-active named
echo FINAL