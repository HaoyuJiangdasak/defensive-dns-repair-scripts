# ccswitch-direct-guard 精简版 (2026-10-15)
# 只做一件事：从 CC Switch 的服务商配置里提取"应直连"的域名，同步到用户级 NO_PROXY。
# 已删除的过度防御层（备份在 D:\_defense_backup_*）：
#   - hosts pin 写死 IP（国内 DNS 会投毒，且会与代理侧解析打架）
#   - 按进程封锁代理端口的防火墙规则（导致 cc-switch 永远无法走代理）
#   - 改写 LeFlyCloud prefs / mihomo 规则（该客户端已停用）
#   - 强制静态 DNS 223.5.5.5（正是投毒来源）
#   - 重复的 ProxyOverride 同步（Verge 自己管，会被它覆盖，互相打架）

$ErrorActionPreference = 'SilentlyContinue'
$script:GuardDir = $PSScriptRoot
$script:LogPath = Join-Path $script:GuardDir 'guard.log'

function Write-GuardLog([string]$msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    try {
        if ((Test-Path $script:LogPath) -and (Get-Item $script:LogPath).Length -gt 262144) {
            Move-Item $script:LogPath ($script:LogPath + '.1') -Force
        }
        Add-Content -Path $script:LogPath -Value $line -Encoding UTF8
    } catch { }
}

function Get-ProviderHosts {
    $js = Join-Path $script:GuardDir 'guard-extract-hosts.js'
    if (-not (Test-Path $js)) { return @() }
    $raw = & node $js 2>$null
    if (-not $raw) { return @() }
    return @(($raw | ConvertFrom-Json) | Where-Object { $_ })
}

function Get-HostSuffix([string]$host_) {
    $parts = $host_.Split('.')
    if ($parts.Count -ge 2) { ($parts[($parts.Count - 2)..($parts.Count - 1)] -join '.') } else { $host_ }
}

function Sync-NoProxy([string[]]$hosts, [string[]]$suffixes) {
    if (-not $hosts -or $hosts.Count -eq 0) { return '(skipped: no hosts)' }
    $items = @()
    foreach ($s in $suffixes) { $items += '*.' + $s; $items += $s }
    foreach ($h in $hosts) { $items += $h }
    $items += 'localhost'; $items += '127.0.0.1'
    $val = ($items | Select-Object -Unique) -join ','
    $cur = [Environment]::GetEnvironmentVariable('NO_PROXY', 'User')
    if ($cur -ne $val) {
        [Environment]::SetEnvironmentVariable('NO_PROXY', $val, 'User')
        Write-GuardLog ("NO_PROXY updated: " + $val)
    }
    return $val
}
