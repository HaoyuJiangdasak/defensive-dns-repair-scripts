# Unix helper

`auto-proxy-switch.sh` 检测本机 HTTP 代理是否可访问，并同步 Git 的全局 `http.proxy` / `https.proxy` 配置。

```bash
PROXY_HOST=127.0.0.1 PROXY_PORT=7890 ./auto-proxy-switch.sh
PROXY_TEST_URL=https://example.com ./auto-proxy-switch.sh
```

脚本会修改 Git 全局配置。需要保持现有代理设置时先备份：

```bash
git config --global --list --show-origin
```
