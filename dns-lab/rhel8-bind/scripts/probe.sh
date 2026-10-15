#!/bin/bash
exec > /tmp/p8_probe.txt 2>&1
systemctl is-active named; systemctl is-enabled named
ss -lntup | grep 53 || true
dig @192.168.72.11 dns.long90.cn A +noall +answer
dig @192.168.72.11 www.long90.cn A +noall +answer
dig @192.168.72.11 slave.long90.cn A +noall +answer
dig @192.168.72.11 ftp.long90.cn A +noall +answer
dig @192.168.72.11 web.long90.cn CNAME +noall +answer
dig @192.168.72.11 -x 192.168.72.11 +noall +answer
dig @192.168.72.11 -x 192.168.72.14 +noall +answer
dig @192.168.72.11 long90.cn NS +noall +answer
dig @192.168.72.11 long90.cn MX +noall +answer
host dns.long90.cn 192.168.72.11
host 192.168.72.13 192.168.72.11
echo PROBE_DONE