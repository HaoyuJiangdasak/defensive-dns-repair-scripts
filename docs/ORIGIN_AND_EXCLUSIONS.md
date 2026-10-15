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

上传前会对仓库执行文本扫描，确认没有邮箱密码、访问令牌、私钥和环境变量密钥。
