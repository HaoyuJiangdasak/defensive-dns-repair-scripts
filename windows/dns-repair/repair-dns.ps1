[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$InterfaceAlias,
    [string[]]$DnsServer,
    [switch]$RestoreDhcp,
    [switch]$FlushCache,
    [switch]$RegisterDns,
    [switch]$ResetWinsock,
    [switch]$ResetTcpIp,
    [string]$BackupPath = (Join-Path $env:TEMP 'dns-client-backup.json')
)

$ErrorActionPreference = 'Stop'

if ($DnsServer -and $RestoreDhcp) {
    throw 'Use either -DnsServer or -RestoreDhcp, not both.'
}

$adapters = @(Get-NetAdapter -ErrorAction Stop | Where-Object Status -eq 'Up')
if ($InterfaceAlias) {
    $adapters = @($adapters | Where-Object Name -eq $InterfaceAlias)
    if ($adapters.Count -eq 0) { throw "Active interface not found: $InterfaceAlias" }
}
if ($adapters.Count -eq 0) { throw 'No active network interface found.' }

$before = foreach ($adapter in $adapters) {
    Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Select-Object InterfaceAlias,InterfaceIndex,ServerAddresses
}
$before | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $BackupPath -Encoding UTF8
Write-Output ("DNS settings backup: " + $BackupPath)

foreach ($adapter in $adapters) {
    if ($DnsServer) {
        if ($PSCmdlet.ShouldProcess($adapter.Name, "Set DNS servers to $($DnsServer -join ', ' )")) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $DnsServer
        }
    } elseif ($RestoreDhcp) {
        if ($PSCmdlet.ShouldProcess($adapter.Name, 'Restore DNS servers from DHCP')) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses
        }
    }
}

if ($FlushCache) {
    if ($PSCmdlet.ShouldProcess('DNS client cache', 'Flush')) {
        Clear-DnsClientCache
        ipconfig /flushdns | Out-Host
    }
}

if ($RegisterDns) {
    if ($PSCmdlet.ShouldProcess('DNS client', 'Register DNS records')) {
        ipconfig /registerdns | Out-Host
    }
}

if ($ResetWinsock) {
    if ($PSCmdlet.ShouldProcess('Winsock catalog', 'Reset')) {
        netsh winsock reset | Out-Host
    }
}

if ($ResetTcpIp) {
    if ($PSCmdlet.ShouldProcess('TCP/IP stack', 'Reset')) {
        netsh int ip reset | Out-Host
    }
}

Write-Output 'DNS repair actions completed.'
