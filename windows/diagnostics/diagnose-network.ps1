[CmdletBinding()]
param(
    [string]$InterfaceAlias,
    [string]$PrimaryWifiProfile,
    [string]$RestoreWifiProfile,
    [string]$ProbeName = 'example.com',
    [int]$WaitAfterConnectSeconds = 20,
    [string]$OutputPath = (Join-Path $env:TEMP 'network-diagnostic.txt'),
    [switch]$SkipWifiSwitch
)

$ErrorActionPreference = 'Continue'

function Write-Section([string]$Title) {
    "`r`n==================== $Title ====================`r`n" | Out-File -FilePath $OutputPath -Append -Encoding utf8
}

function Write-Text([string]$Value) {
    $Value | Out-File -FilePath $OutputPath -Append -Encoding utf8
}

function Connect-Wifi([string]$Profile) {
    if (-not $Profile) { return }
    $args = @('wlan', 'connect', "name=$Profile")
    if ($InterfaceAlias) { $args += "interface=$InterfaceAlias" }
    Write-Text ((netsh @args | Out-String))
}

function Snapshot([string]$Tag) {
    Write-Section "$Tag :: interfaces"
    Write-Text ((Get-NetAdapter -ErrorAction SilentlyContinue | Format-Table -AutoSize | Out-String))

    Write-Section "$Tag :: IP configuration"
    Write-Text ((Get-NetIPConfiguration -ErrorAction SilentlyContinue | Format-List * | Out-String))

    Write-Section "$Tag :: connection profiles"
    Write-Text ((Get-NetConnectionProfile -ErrorAction SilentlyContinue | Format-List * | Out-String))

    Write-Section "$Tag :: default routes"
    Write-Text ((Get-NetRoute -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Sort-Object RouteMetric | Format-Table -AutoSize | Out-String))

    Write-Section "$Tag :: DNS servers"
    if ($InterfaceAlias) {
        Write-Text ((Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Select-Object InterfaceAlias,ServerAddresses | Format-List | Out-String))
    } else {
        Write-Text ((Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Select-Object InterfaceAlias,ServerAddresses | Format-Table -AutoSize | Out-String))
    }
}

Remove-Item -LiteralPath $OutputPath -ErrorAction SilentlyContinue
Write-Text 'Windows network diagnostic'
Write-Text ("start: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Snapshot 'BASELINE'

if (-not $SkipWifiSwitch -and $PrimaryWifiProfile) {
    Write-Section 'CONNECT -> PRIMARY WIFI'
    Connect-Wifi $PrimaryWifiProfile
    Start-Sleep -Seconds $WaitAfterConnectSeconds
    Snapshot 'PRIMARY WIFI'
}

Write-Section 'DNS AND CONNECTIVITY PROBES'
if ($InterfaceAlias) {
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue | Select-Object -First 1
} else {
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Select-Object -First 1
}
Write-Text ("gateway = " + $route.NextHop)
if ($route.NextHop) { Write-Text ((ping -n 3 $route.NextHop | Out-String)) }
Write-Text ("resolve $ProbeName")
Write-Text ((Resolve-DnsName -Name $ProbeName -ErrorAction SilentlyContinue | Out-String))
Write-Text ((Test-NetConnection -ComputerName $ProbeName -InformationLevel Detailed -WarningAction SilentlyContinue | Out-String))

if (-not $SkipWifiSwitch -and $RestoreWifiProfile) {
    Write-Section 'RESTORE WIFI'
    Connect-Wifi $RestoreWifiProfile
    Start-Sleep -Seconds $WaitAfterConnectSeconds
    Snapshot 'RESTORED'
}

Write-Text ("end: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Text ("log: " + $OutputPath)
Write-Output $OutputPath
