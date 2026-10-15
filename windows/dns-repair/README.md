# Windows DNS repair

`repair-dns.ps1` 先保存当前活动网卡的 IPv4 DNS 设置，再按显式参数执行修复。它不会默认写入任何公共 DNS。

```powershell
# 只查看将要执行的操作
.\repair-dns.ps1 -InterfaceAlias 'WLAN' -DnsServer 192.168.1.1,192.168.1.2 -FlushCache -WhatIf

# 设置指定 DNS 并清理缓存
.\repair-dns.ps1 -InterfaceAlias 'WLAN' -DnsServer 192.168.1.1,192.168.1.2 -FlushCache

# 恢复 DHCP 下发的 DNS
.\repair-dns.ps1 -InterfaceAlias 'WLAN' -RestoreDhcp -FlushCache

# 只在确认需要时重置网络栈；通常需要管理员权限并可能要求重启
.\repair-dns.ps1 -ResetWinsock -ResetTcpIp
```

备份默认写入 `%TEMP%\dns-client-backup.json`，可用 `-BackupPath` 指定其他位置。`-DnsServer` 与 `-RestoreDhcp` 不能同时使用。
