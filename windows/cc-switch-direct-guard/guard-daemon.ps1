# cc-switch direct-guard daemon (精简版): 周期同步 NO_PROXY
$lib = Join-Path $PSScriptRoot 'guard-lib.ps1'
. $lib
$mutexName = 'CCSwitchDirectGuardDaemon'
$mutex = New-Object System.Threading.Mutex($false, $mutexName)
if (-not $mutex.WaitOne(0, $false)) { exit 0 }
Write-GuardLog 'daemon started (slim: NO_PROXY only)'
while ($true) {
    try {
        $hosts = Get-ProviderHosts
        $suffixes = @($hosts | ForEach-Object { Get-HostSuffix $_ } | Select-Object -Unique)
        if ($hosts.Count -gt 0) {
            Sync-NoProxy $hosts $suffixes | Out-Null
            Write-GuardLog ("cycle: hosts=" + $hosts.Count + " suffixes=" + $suffixes.Count)
        }
    } catch {
        Write-GuardLog ("cycle error: " + $_)
    }
    Start-Sleep -Seconds 300
}
