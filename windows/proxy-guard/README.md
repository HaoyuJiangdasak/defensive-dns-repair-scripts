# Windows proxy guard

`proxy_guard.py` 检测 Windows 系统代理是否指向本机端口。端口没有进程监听时，`--fix` 会关闭残留系统代理；发现可用本地代理时，它还会同步用户级 `HTTP_PROXY`、`HTTPS_PROXY`、`NODE_USE_ENV_PROXY` 和 Git 的全局代理设置。

```powershell
python proxy_guard.py --status
python proxy_guard.py --fix
pythonw proxy_guard.py
```

守护模式会持续运行，并写入脚本目录下的 `proxy_guard.log`。它会修改注册表中的 Internet Settings、用户环境变量和 Git 全局配置。首次使用前保存当前配置，确认本机代理端口候选列表（脚本顶部的 `CANDIDATE_PORTS`）符合实际环境。

仓库不包含原目录中的日志、开机自启 VBS 和计划任务安装器，避免把本机路径带入复用环境。需要自动启动时，请使用系统任务计划程序显式指定当前 Python 解释器和脚本路径。
