# -*- coding: utf-8 -*-
"""
proxy_guard.py — 本机代理唯一守护者（2026-10-15 合并版）

职责（其余重复的防御层已删除）:
  1. 系统代理残留清理: 系统代理指向本机端口但无人监听 -> 立即关闭
  2. 环境变量代理同步: 有活的本地代理 -> 写 HTTP(S)_PROXY + NODE_USE_ENV_PROXY,
     没有 -> 清除（Node 24 的 fetch 只在 NODE_USE_ENV_PROXY=1 时才认代理环境变量）
  3. git 全局代理同步: 同上

用法:
  pythonw proxy_guard.py            # 守护模式(开机自启)
  python  proxy_guard.py --fix      # 立即执行一次
  python  proxy_guard.py --status   # 查看状态
"""
import sys
import os
import time
import socket
import ctypes
import subprocess
import datetime

import winreg

POLL_SECONDS = 1
DEAD_STREAK_NEEDED = 2
ENV_SYNC_TICKS = 30
MUTEX_PORT = 59641
CANDIDATE_PORTS = (7897, 7890, 7898, 7899, 10808, 1080)
IE_KEY = r"Software\Microsoft\Windows\CurrentVersion\Internet Settings"
ENV_NAMES = ("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy")
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_PATH = os.path.join(BASE_DIR, "proxy_guard.log")
LOG_MAX_BYTES = 512 * 1024
STARTUP_VBS = os.path.join(
    os.environ.get("APPDATA", ""),
    "Microsoft", "Windows", "Start Menu", "Programs", "Startup", "proxy-guard.vbs")
SELF_PATH = os.path.abspath(__file__)


def log(msg):
    line = "[%s] %s\n" % (datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), msg)
    try:
        if os.path.exists(LOG_PATH) and os.path.getsize(LOG_PATH) > LOG_MAX_BYTES:
            if os.path.exists(LOG_PATH + ".1"):
                os.remove(LOG_PATH + ".1")
            os.replace(LOG_PATH, LOG_PATH + ".1")
        with open(LOG_PATH, "a", encoding="utf-8") as f:
            f.write(line)
    except OSError:
        pass


def read_proxy():
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, IE_KEY) as k:
            enable = winreg.QueryValueEx(k, "ProxyEnable")[0]
            try:
                server = winreg.QueryValueEx(k, "ProxyServer")[0]
            except OSError:
                server = ""
        return enable, server
    except OSError:
        return 0, ""


def notify_wininet():
    try:
        wi = ctypes.windll.wininet
        wi.InternetSetOptionW(None, 39, None, 0)   # SETTINGS_CHANGED
        wi.InternetSetOptionW(None, 37, None, 0)   # REFRESH
    except Exception:
        pass


def disable_proxy():
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, IE_KEY, 0, winreg.KEY_SET_VALUE) as k:
        winreg.SetValueEx(k, "ProxyEnable", 0, winreg.REG_DWORD, 0)
        try:
            winreg.DeleteValue(k, "ProxyServer")
        except OSError:
            pass
    notify_wininet()


def parse_endpoints(server):
    eps = []
    for token in str(server).replace(";", ",").split(","):
        token = token.strip()
        if not token:
            continue
        if "=" in token:
            token = token.split("=", 1)[1].strip()
        if ":" not in token:
            continue
        host, _, port_s = token.rpartition(":")
        host = host.strip("[]").strip()
        try:
            port = int(port_s)
        except ValueError:
            continue
        if host and 0 < port < 65536:
            eps.append((host, port))
    return eps


def is_local(host):
    h = host.lower()
    return h in ("127.0.0.1", "localhost", "::1") or h.startswith("127.")


def port_alive(host, port, timeout=0.8):
    fam = socket.AF_INET6 if ":" in host else socket.AF_INET
    s = socket.socket(fam, socket.SOCK_STREAM)
    s.settimeout(timeout)
    try:
        s.connect((host, port))
        return True
    except OSError:
        return False
    finally:
        s.close()


def live_proxy_endpoint():
    """优先用系统代理已指向的端口，其次扫描候选端口。返回 (host, port) 或 None。"""
    enable, server = read_proxy()
    if enable and server:
        eps = [(h, p) for h, p in parse_endpoints(server) if is_local(h) and port_alive(h, p)]
        if eps:
            return eps[0]
    for port in CANDIDATE_PORTS:
        if port_alive("127.0.0.1", port, 0.4):
            return ("127.0.0.1", port)
    return None


def set_user_env(name, value):
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment", 0, winreg.KEY_SET_VALUE) as k:
        if value is None:
            try:
                winreg.DeleteValue(k, name)
            except OSError:
                pass
        else:
            winreg.SetValueEx(k, name, 0, winreg.REG_SZ, value)


def get_user_env(name):
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as k:
            return winreg.QueryValueEx(k, name)[0]
    except OSError:
        return None


def broadcast_env_change():
    """让新启动的 GUI 程序立刻看到改过的用户环境变量，不必等到下次登录。"""
    try:
        u = ctypes.windll.user32
        hwnd_bcast = 0xFFFF
        WM_SETTINGCHANGE = 0x001A
        SMTO_ABORTIFHUNG = 0x0002
        buf = ctypes.c_wchar_p("Environment")
        res = ctypes.c_void_p(0)
        u.SendMessageTimeoutW(hwnd_bcast, WM_SETTINGCHANGE, 0, buf, SMTO_ABORTIFHUNG, 1000,
                              ctypes.byref(res))
    except Exception:
        pass


def git_config(args, value=None):
    try:
        cmd = ["git", "config", "--global"] + list(args)
        if value is not None:
            cmd.append(value)
        subprocess.run(cmd, capture_output=True, timeout=10,
                       creationflags=0x08000000 if os.name == "nt" else 0)
    except Exception:
        pass


def git_get(key):
    try:
        r = subprocess.run(["git", "config", "--global", key], capture_output=True, text=True,
                           timeout=10, creationflags=0x08000000 if os.name == "nt" else 0)
        return (r.stdout or "").strip()
    except Exception:
        return ""


def sync_client_proxy_env(verbose=False):
    """Keep env-proxy + git-proxy consistent with whether a local proxy is alive."""
    ep = live_proxy_endpoint()
    url = "http://127.0.0.1:%d" % ep[1] if ep else None
    changed = False

    if url:
        if get_user_env("NODE_USE_ENV_PROXY") != "1":
            set_user_env("NODE_USE_ENV_PROXY", "1")
            changed = True
        for n in ENV_NAMES:
            if get_user_env(n) != url:
                set_user_env(n, url)
                changed = True
        for key in ("http.proxy", "https.proxy"):
            if git_get(key) != url:
                git_config([key], url)
                changed = True
    else:
        for n in ENV_NAMES:
            if get_user_env(n) is not None:
                set_user_env(n, None)
                changed = True
        for key in ("http.proxy", "https.proxy"):
            if git_get(key):
                git_config(["--unset", key])
                changed = True

    if changed:
        notify_wininet()
        broadcast_env_change()
        log("客户端代理环境同步: %s" % (url or "已清除(无存活代理)"))
        if verbose:
            print("env/git proxy synced -> %s" % (url or "cleared"))
    return changed


def try_fix(verbose=False):
    enable, server = read_proxy()
    if not enable or not server:
        if verbose:
            print("系统代理未启用，无需修复。")
        sync_client_proxy_env(verbose=verbose)
        return False
    eps = parse_endpoints(server)
    if not eps:
        if verbose:
            print("代理配置无法解析: %s" % server)
        return False
    if not all(is_local(h) for h, _ in eps):
        if verbose:
            print("检测到非本机代理 (%s)，不自动处理。" % server)
        return False
    if any(port_alive(h, p) for h, p in eps):
        if verbose:
            print("代理软件正在运行 (%s)，无需修复。" % server)
        sync_client_proxy_env(verbose=verbose)
        return False
    if verbose:
        print("检测到残留代理 (%s, 端口无人监听)，正在关闭..." % server)
    disable_proxy()
    log("修复: %s 无进程监听，已关闭系统代理" % server)
    sync_client_proxy_env(verbose=verbose)
    if verbose:
        print("已关闭系统代理，浏览器可以直接上网了。")
    return True


def ensure_autostart():
    """开机自启脚本丢失时重建，保证守护本身不被悄悄关掉。"""
    try:
        if not STARTUP_VBS or os.path.isdir(os.path.dirname(STARTUP_VBS)):
            if os.path.exists(STARTUP_VBS):
                with open(STARTUP_VBS, "r", encoding="utf-8", errors="ignore") as f:
                    if "proxy_guard.py" in f.read():
                        return
                pythonw = os.path.join(os.path.dirname(sys.executable), "pythonw.exe")
                vbs = (
                    "' ProxyGuard autostart\r\n"
                    "Dim sh\r\n"
                    "Set sh = CreateObject(\"WScript.Shell\")\r\n"
                    "sh.Run \"\"\"%s\"\" \"\"%s\"\"\", 0, False\r\n" % (pythonw, SELF_PATH))
                with open(STARTUP_VBS, "w", encoding="utf-8") as f:
                    f.write(vbs)
                log("自愈: 已重建开机自启脚本")
    except Exception as e:
        log("自愈检查出错: %r" % (e,))


def guard_loop():
    lock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    lock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)  # 避免旧实例刚退出时 TIME_WAIT 导致误判"已有守护"
    try:
        lock.bind(("127.0.0.1", MUTEX_PORT))
        lock.listen(1)
    except OSError:
        return
    log("守护启动 (间隔 %ss, 含 env/git 同步) [v3]" % POLL_SECONDS)
    dead_streak = 0
    ticks = 0
    while True:
        try:
            if ticks % 600 == 0:
                ensure_autostart()
            if ticks % ENV_SYNC_TICKS == 0:
                sync_client_proxy_env()
            ticks += 1
            enable, server = read_proxy()
            eps = parse_endpoints(server) if (enable and server) else []
            if eps and all(is_local(h) for h, _ in eps):
                if any(port_alive(h, p) for h, p in eps):
                    dead_streak = 0
                else:
                    dead_streak += 1
                    if dead_streak >= DEAD_STREAK_NEEDED:
                        dead_streak = 0
                        if not any(port_alive(h, p) for h, p in eps):
                            disable_proxy()
                            log("修复: %s 无进程监听，已关闭系统代理" % server)
            else:
                dead_streak = 0
        except Exception as e:
            log("检查出错: %r" % (e,))
        time.sleep(POLL_SECONDS)


def show_status():
    enable, server = read_proxy()
    print("系统代理: " + ("已启用 -> %s" % server if enable else "未启用"))
    if enable and server:
        for h, p in parse_endpoints(server):
            print("  - %s:%s (%s, %s)" % (h, p, "本机" if is_local(h) else "远程",
                                          "监听中" if port_alive(h, p) else "无监听"))
    ep = live_proxy_endpoint()
    print("存活本地代理: %s" % ("127.0.0.1:%d" % ep[1] if ep else "无"))
    for n in ("NODE_USE_ENV_PROXY",) + ENV_NAMES:
        print("  %-18s = %s" % (n, get_user_env(n)))
    print("  git http.proxy       = %s" % (git_get("http.proxy") or "(未设置)"))


def main():
    args = set(a.lower() for a in sys.argv[1:])
    if "--fix" in args:
        try_fix(verbose=True)
    elif "--status" in args:
        show_status()
    else:
        guard_loop()


if __name__ == "__main__":
    main()
