# RHEL 8 BIND lab

这套脚本对应本机项目 8 的 RHEL 8 BIND 实验，默认拓扑为：

| 节点 | 地址 | 角色 |
|---|---:|---|
| Server01 | `192.168.72.11` | 权威 DNS |
| Server02 | `192.168.72.12` | 缓存/转发 DNS |
| Client1 | `192.168.72.20` | Linux 客户端 |

示例域为 `long90.cn`，区域文件位于 `config/`，动作和验收脚本位于 `scripts/`。多数脚本会把输出写到目标 RHEL 主机的 `/tmp/p8_*.txt`，并假设已经安装 `bind`, `bind-utils` 和 `firewalld`。

## 推荐顺序

1. 把 `config/` 文件复制到目标机上脚本约定的位置（默认 `/tmp/p8/`），检查网段、接口和域名。
2. 在 Server01 执行 `setup_bind.sh`，再执行 `probe.sh` 或 `s01.sh`。
3. 在 Server02 执行 `s02_bind.sh`，在 Client1 执行 `client1_dns.sh` 或 `r_c1.sh`。
4. 发生服务或防火墙问题时先查看输出，再按需执行 `fix_named.sh`、`fw.sh` 或 `r_tcpfix.sh`。

`fix_named.sh` 会停止并禁用 `firewalld` 后再尝试恢复；只有在理解该副作用并准备好恢复策略时才使用。生产环境应先改成显式的最小防火墙规则。
