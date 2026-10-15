#!/bin/bash
exec > /tmp/p8_c1_via_s2.txt 2>&1
echo '=== dig @Server02 ==='
dig @192.168.72.12 www.long90.cn A +noall +answer
dig @192.168.72.12 long90.cn MX +noall +answer
dig @192.168.72.12 dns.long90.cn A +noall +answer
dig @192.168.72.12 -x 192.168.72.11 +noall +answer
host ftp.long90.cn 192.168.72.12
echo C1_VIA_S2_DONE