# Defensive DNS and repair scripts

这是一份从本机实验目录整理出的网络诊断、BIND DNS 配置/验收和 Windows 代理残留修复脚本集。仓库按用途分目录，源码可以单独取用。

## 目录

- `dns-lab/rhel8-bind/config/`：RHEL 8 BIND 的示例配置和正向/反向区域文件。
- `dns-lab/rhel8-bind/scripts/`：安装、修复、检查和客户端验收脚本。
- `windows/proxy-guard/`：检测本机代理端口并清理失效系统代理，同时同步用户级代理环境变量和 Git 代理。
- `windows/cc-switch-direct-guard/`：从 CC Switch 服务商配置提取应直连域名并同步 `NO_PROXY` 的精简守护脚本。
- `windows/diagnostics/`：不带本机 SSID、账号和路径的 Windows 网络诊断脚本。
- `docs/`：使用说明和整理记录。

## 使用前

脚本会读取或修改网络配置、Windows 注册表、用户环境变量、Git 全局配置、BIND 服务和防火墙。先阅读对应目录的说明，并在测试机或快照中运行。DNS 实验脚本默认使用教学实验网 `192.168.72.0/24` 和示例域 `long90.cn`，部署到其他网络前请统一替换地址、接口名和域名。

仓库刻意不包含虚拟机磁盘、截图、运行日志、注册表导出、hosts 快照、任务计划 XML、账号总结和本机 CC Switch 数据库。

## 快速入口

```text
# Windows 代理状态/一次性修复
python windows/proxy-guard/proxy_guard.py --status
python windows/proxy-guard/proxy_guard.py --fix

# RHEL 8 BIND（将 config/ 文件按说明放到目标机后执行）
sudo bash dns-lab/rhel8-bind/scripts/setup_bind.sh
```

`proxy_guard.py` 的守护模式会持续运行并同步代理设置；需要常驻运行时再直接启动，不建议在未审阅的环境中加入开机自启。

## 来源

DNS 文件来自 `D:\项目8_DNS\scripts`，代理守护程序来自 `D:\ProxyGuard\proxy_guard.py`，CC Switch 精简守护程序来自用户目录中的 `ccswitch-direct-guard`，网络诊断脚本经过参数化整理。原始文件保留在本机原目录中，仓库版本用于复用和审阅。
