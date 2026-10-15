#!/bin/bash
exec > /tmp/p8r_s01.txt 2>&1
echo "=== IDENTITY ==="
hostname; cat /etc/redhat-release; id
ip -4 addr show ens33 || ip -4 addr
ip route
echo "=== FIREWALL / SELINUX ==="
systemctl is-active firewalld || echo firewalld_inactive
systemctl is-enabled firewalld 2>/dev/null || true
getenforce 2>/dev/null || true
echo "=== NAMED ==="
systemctl is-active named; systemctl is-enabled named
ss -lntup | grep ':53' || true
echo "=== CHECK ==="
named-checkconf; echo checkconf_rc=$?
named-checkzone long90.cn /var/named/long90.cn.zone; echo zf=$?
named-checkzone 72.168.192.in-addr.arpa /var/named/72.168.192.zone; echo zr=$?
ls -la /etc/named.conf /etc/named.zones /var/named/long90.cn.zone /var/named/72.168.192.zone
echo "=== ZONE SNIPPET ==="
head -30 /var/named/long90.cn.zone
echo "=== DIG @.11 ==="
dig @192.168.72.11 dns.long90.cn A +noall +answer
dig @192.168.72.11 mail.long90.cn A +noall +answer
dig @192.168.72.11 slave.long90.cn A +noall +answer
dig @192.168.72.11 www.long90.cn A +noall +answer
dig @192.168.72.11 ftp.long90.cn A +noall +answer
dig @192.168.72.11 web.long90.cn CNAME +noall +answer
dig @192.168.72.11 -x 192.168.72.11 +noall +answer
dig @192.168.72.11 -x 192.168.72.12 +noall +answer
dig @192.168.72.11 -x 192.168.72.14 +noall +answer
dig @192.168.72.11 long90.cn NS +noall +answer
dig @192.168.72.11 long90.cn MX +noall +answer
host 192.168.72.13 192.168.72.11
echo S01_REPLAY_DONE