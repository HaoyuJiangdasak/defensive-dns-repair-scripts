# 整理记录

## 纳入

- `D:\项目8_DNS\scripts`：BIND 配置、区域文件、安装脚本、修复脚本和验收脚本。
- `D:\ProxyGuard\proxy_guard.py`：代理残留检测和环境同步工具。
- `Documents\ccswitch-direct-guard`：当前精简版 `NO_PROXY` 同步工具。
- `hubu-net-diag.ps1`：改写为参数化的 `windows/diagnostics/diagnose-network.ps1`，去掉了本机 Wi-Fi 名称和个人环境默认值。

## 排除

- `D:\项目8_DNS\VM` 下的虚拟磁盘、VMware 状态和运行日志；
- 桌面项目中的截图、复现证据和交接文档；
- `D:\ProxyGuard` 与 CC Switch 目录中的日志、hosts 快照、注册表导出、任务计划 XML、旧版备份和本机清单；
- 含有真实账号、密码、令牌、API key、代理日志或本机配置的文件。

盘点后仍保留在本机、但未上传的相关文件包括：`D:\项目8_DNS\Capture-Evidence.ps1` 和 `Capture-Screen.ps1`（仅用于实验截图/证据生成）、旧版 `guard-apply.ps1`/`guard-watchdog.ps1` 及其 hosts/防火墙补丁（已被当前精简版取代）、旧版双份 `proxy_guard.py` 和安装器、硬编码 hosts 的 `append-hosts.ps1`，以及带本机路径的计划任务批处理文件。这些文件要么属于证据采集，要么会写入固定本机路径或旧的防御层，因此保留在本机归档中。

上传前会对仓库执行文本扫描，确认没有邮箱密码、访问令牌、私钥和环境变量密钥。
