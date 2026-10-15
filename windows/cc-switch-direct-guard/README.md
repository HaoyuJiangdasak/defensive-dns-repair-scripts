# CC Switch direct guard

这组三个文件组成精简版直连域名守护：Node 脚本只读 CC Switch 的本地数据库，提取服务商网站域名；PowerShell 守护程序把这些域名及其后缀同步到用户级 `NO_PROXY`。

运行前需要：

- Node.js 版本提供 `node:sqlite`；
- 本机存在 `~/.cc-switch/cc-switch.db`；
- PowerShell 能读取本目录。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\guard-daemon.ps1
```

`guard-daemon.ps1` 是常驻循环，会每 5 分钟更新一次用户环境变量。仓库只保留当前精简版：旧版 hosts 固定 IP、防火墙封锁、第三方客户端补丁和运行日志均未纳入。
