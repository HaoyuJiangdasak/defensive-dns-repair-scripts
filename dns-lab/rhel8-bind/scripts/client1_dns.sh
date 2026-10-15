#!/bin/bash
exec > /tmp/p8_client1.txt 2>&1
hostname
ip -4 addr
cat /etc/redhat-release
# set DNS via nmcli if possible
IF=$(nmcli -t -f DEVICE,STATE device | awk -F: '$2=="connected"{print $1; exit}')
echo IF=$IF
CON=$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v d="$IF" '$2==d{print $1; exit}')
echo CON=$CON
if [ -n "$CON" ]; then
  nmcli connection modify "$CON" ipv4.dns "192.168.72.11 192.168.72.12" ipv4.dns-search long90.cn ipv4.ignore-auto-dns yes || true
  nmcli connection up "$CON" || true
fi
echo '=== resolv.conf ==='
cat /etc/resolv.conf || true
echo '=== dig via Server01 ==='
dig @192.168.72.11 dns.long90.cn A +noall +answer
dig @192.168.72.11 www.long90.cn A +noall +answer
dig @192.168.72.11 web.long90.cn CNAME +noall +answer
dig @192.168.72.11 mail.long90.cn A +noall +answer
dig @192.168.72.11 slave.long90.cn A +noall +answer
dig @192.168.72.11 ftp.long90.cn A +noall +answer
dig @192.168.72.11 -x 192.168.72.11 +noall +answer
dig @192.168.72.11 -x 192.168.72.14 +noall +answer
dig @192.168.72.11 long90.cn NS +noall +answer
dig @192.168.72.11 long90.cn MX +noall +answer
host www.long90.cn 192.168.72.11
ping -c 2 192.168.72.11 || true
echo CLIENT1_DNS_DONE