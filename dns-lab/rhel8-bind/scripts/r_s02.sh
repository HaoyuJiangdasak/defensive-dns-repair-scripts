#!/bin/bash
exec > /tmp/p8r_s02.txt 2>&1
echo "=== IDENTITY ==="
hostname; cat /etc/redhat-release
ip -4 addr show ens33 || ip -4 addr
echo "=== FIREWALL ==="
systemctl is-active firewalld || echo firewalld_inactive
systemctl is-enabled firewalld 2>/dev/null || true
echo "=== NAMED FWD ==="
systemctl is-active named; systemctl is-enabled named
grep -E 'forward|listen|allow-query|recursion' /etc/named.conf || true
ss -lntup | grep ':53' || true
named-checkconf; echo checkconf_rc=$?
echo "=== DIG via .12 ==="
dig @192.168.72.12 www.long90.cn A +noall +answer
dig @192.168.72.12 dns.long90.cn A +noall +answer
dig @192.168.72.12 long90.cn MX +noall +answer
dig @192.168.72.12 web.long90.cn +noall +answer
dig @192.168.72.12 -x 192.168.72.11 +noall +answer
echo S02_REPLAY_DONE