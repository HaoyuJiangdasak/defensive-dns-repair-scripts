#!/bin/bash
exec > /tmp/p8_bind_log.txt 2>&1
echo START
cp /tmp/p8/named.conf /etc/named.conf
cp /tmp/p8/named.zones /etc/named.zones
cp /tmp/p8/long90.cn.zone /var/named/long90.cn.zone
cp /tmp/p8/72.168.192.zone /var/named/72.168.192.zone
chgrp named /etc/named.conf /etc/named.zones || true
chown root:named /var/named/long90.cn.zone /var/named/72.168.192.zone || true
chmod 640 /var/named/long90.cn.zone /var/named/72.168.192.zone || true
restorecon -Rv /etc/named.conf /etc/named.zones /var/named || true
echo CHECKCONF
named-checkconf; echo checkconf_rc=$?
named-checkzone long90.cn /var/named/long90.cn.zone; echo checkzone_fwd_rc=$?
named-checkzone 72.168.192.in-addr.arpa /var/named/72.168.192.zone; echo checkzone_rev_rc=$?
firewall-cmd --permanent --add-service=dns || true
firewall-cmd --reload || true
systemctl enable named || true
systemctl restart named
sleep 2
systemctl is-active named; systemctl is-enabled named
ss -lntup | grep 53 || netstat -lntup | grep 53 || true
echo DIG
dig @127.0.0.1 dns.long90.cn A +noall +answer
dig @127.0.0.1 www.long90.cn A +noall +answer
dig @127.0.0.1 web.long90.cn +noall +answer
dig @127.0.0.1 -x 192.168.72.11 +noall +answer
dig @127.0.0.1 long90.cn NS +noall +answer
dig @127.0.0.1 long90.cn MX +noall +answer
echo DONE