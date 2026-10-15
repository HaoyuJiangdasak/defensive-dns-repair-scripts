#!/bin/bash
set -e
cp -a /etc/named.conf /etc/named.conf.bak.$(date +%Y%m%d%H%M%S) 2>/dev/null || true
cp /tmp/p8/named.conf /etc/named.conf
cp /tmp/p8/named.zones /etc/named.zones
cp /tmp/p8/long90.cn.zone /var/named/long90.cn.zone
cp /tmp/p8/72.168.192.zone /var/named/72.168.192.zone
chgrp named /etc/named.conf /etc/named.zones
chown root:named /var/named/long90.cn.zone /var/named/72.168.192.zone
chmod 640 /var/named/long90.cn.zone /var/named/72.168.192.zone
restorecon -Rv /etc/named.conf /etc/named.zones /var/named 2>/dev/null || true
named-checkconf
named-checkzone long90.cn /var/named/long90.cn.zone
named-checkzone 72.168.192.in-addr.arpa /var/named/72.168.192.zone
firewall-cmd --permanent --add-service=dns || true
firewall-cmd --reload || true
systemctl enable named
systemctl restart named
systemctl --no-pager --full status named | head -30
ss -lntup | grep ':53' || true
{
  echo "=== dig tests ==="
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
  host dns.long90.cn 192.168.72.11
  host 192.168.72.13 192.168.72.11
} | tee /tmp/p8_dig.txt
echo BIND_SETUP_OK