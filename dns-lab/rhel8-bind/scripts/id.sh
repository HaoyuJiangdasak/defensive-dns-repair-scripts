#!/bin/bash
set -x
{
  echo "=== HOST ==="
  hostname
  cat /etc/redhat-release
  id
  ip -4 addr
  ip route
  rpm -qa | grep -E '^bind' || true
  systemctl is-active sshd || true
  getent passwd "${USER_TO_CHECK:-$USER}" || true
  ls -la /home || true
} > /tmp/p8_id.txt 2>&1
