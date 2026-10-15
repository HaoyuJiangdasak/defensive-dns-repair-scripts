#!/bin/bash
exec > /tmp/p8r_c1.txt 2>&1
echo "=== IDENTITY ==="
hostname; cat /etc/redhat-release
ip -4 addr show ens33 || ip -4 addr
echo "=== resolv.conf ==="
cat /etc/resolv.conf
echo "=== dig @.11 ==="
dig @192.168.72.11 dns.long90.cn A +short
dig @192.168.72.11 www.long90.cn A +short
dig @192.168.72.11 web.long90.cn +short
dig @192.168.72.11 long90.cn NS +short
dig @192.168.72.11 long90.cn MX +short
dig @192.168.72.11 -x 192.168.72.14 +short
echo "=== dig @.12 ==="
dig @192.168.72.12 www.long90.cn A +short
dig @192.168.72.12 long90.cn MX +short
dig @192.168.72.12 ftp.long90.cn A +short
dig @192.168.72.12 -x 192.168.72.11 +short
echo "=== nslookup ==="
nslookup www.long90.cn 192.168.72.11 || true
nslookup dns.long90.cn 192.168.72.12 || true
ping -c 2 192.168.72.11
ping -c 2 192.168.72.12
echo C1_REPLAY_DONE