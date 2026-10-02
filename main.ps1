# fgp - Fingerprint Generator (PowerShell)
# Generates: fgp_<sha256>

function Get-LocalIPv4 {
    Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' } |
        Select-Object -First 1 -ExpandProperty IPAddress
}

function Get-MacAddress {
    Get-NetAdapter |
        Where-Object { $_.Status -eq 'Up' } |
        Select-Object -First 1 -ExpandProperty MacAddress
}

function Get-OsInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    "$($os.Caption) $($os.Version)"
}

function Get-UserAgent {
    $os = Get-OsInfo
    $ps = $PSVersionTable.PSVersion.ToString()
    "fgp/1.0 ($os; PowerShell/$ps)"
}

function Get-Sha256Hex {
    param([string]$InputString)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha.ComputeHash($bytes)
    ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ""
}

function New-FgpId {

    $ip        = Get-LocalIPv4
    $mac       = Get-MacAddress
    $hostname  = $env:COMPUTERNAME
    $username  = $env:USERNAME
    $os        = Get-OsInfo
    $ua        = Get-UserAgent

    # Normalized fingerprint string
    $fingerprint = @(
        "hostname=$hostname",
        "ip=$ip",
        "mac=$mac",
        "os=$os",
        "ua=$ua",
        "user=$username"
    ) -join "&"

    Write-Host "Fingerprint:"
    Write-Host $fingerprint
    Write-Host ""

    $hash = Get-Sha256Hex -InputString $fingerprint
    $fgp = "fgp_$hash"

    Write-Host "Generated fgp ID:"
    Write-Host $fgp

    return $fgp
}

# Run generator
New-FgpId
