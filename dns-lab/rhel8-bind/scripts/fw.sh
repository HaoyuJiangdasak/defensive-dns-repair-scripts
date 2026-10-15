#!/bin/bash
exec > /tmp/p8_fw.txt 2>&1
timeout 20 systemctl start firewalld || true
timeout 15 firewall-cmd --permanent --add-service=dns || true
timeout 15 firewall-cmd --reload || true
firewall-cmd --list-services || true
systemctl is-active named
echo FW_DONE