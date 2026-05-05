#requires -Version 7.0
<#
.SYNOPSIS
Checks DNS resolvers from IPv4/IPv6 CSV lists against a baseline and updates reliability and checked_at.

.DESCRIPTION
This script reads two CSV files containing DNS resolvers (IPv4 and IPv6), resolves a target domain via each
resolver with a robust timeout, compares returned A/AAAA answers against a baseline resolver, and updates:
  - reliability: 1.0 for exact match (A or AAAA), 0.8 for any answer, 0.0 for no answer
  - checked_at: current UTC timestamp (ISO 8601). For IPv6, updates the last checked_at column when duplicates exist.

It shows a live progress bar and runs checks in parallel with a configurable throttle.

.PARAMETER IPv4Path
Path to the IPv4 resolvers CSV (optional, can be omitted to process only IPv6).

.PARAMETER IPv6Path
Path to the IPv6 resolvers CSV (optional, can be omitted to process only IPv4).

.PARAMETER Domain
The domain to resolve for baseline and per-resolver checks. Defaults to news.google.com.au.

.PARAMETER BaselineServer
IP address of the baseline resolver used to compute reference A/AAAA answers. Defaults to 10.1.14.30.

.PARAMETER ThrottleLimit
Maximum parallel checks. Lower values reduce the chance of long hangs. Default 75.

.PARAMETER PerResolverTimeoutSec
Timeout in seconds for each resolver query when using nslookup. Default 5.

.FILECREATED
2026-01-19

.FILELASTUPDATED
2026-01-19

#>

param(
  [Parameter(Mandatory = $false)]
  [string]$IPv4Path,
  [Parameter(Mandatory = $false)]
  [string]$IPv6Path,
  [string]$Domain = 'news.google.com.au',
  [string]$BaselineServer = '10.1.14.30',
  [ValidateRange(1, 1000)]
  [int]$ThrottleLimit = 75,
  [ValidateRange(1, 60)]
  [int]$PerResolverTimeoutSec = 5,
  [switch]$LowResourceMode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $IPv4Path -and -not $IPv6Path) {
  throw 'Provide at least one CSV path: -IPv4Path and/or -IPv6Path.'
}

if ($IPv4Path -and -not (Test-Path -Path $IPv4Path -PathType Leaf)) {
  throw ('IPv4 CSV not found: {0}' -f $IPv4Path)
}
if ($IPv6Path -and -not (Test-Path -Path $IPv6Path -PathType Leaf)) {
  throw ('IPv6 CSV not found: {0}' -f $IPv6Path)
}

function Get-DnsAnswersViaNslookup {
  param(
    [Parameter(Mandatory = $true)][string]$Server,
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][int]$TimeoutSec
  )
  # Uses nslookup with timeout to fetch A and AAAA answers.
  # Enters the answer section when 'Non-authoritative answer:', 'Answer:', 'Name:' or 'Aliases:' appears
  # and captures 'Address:' and 'Addresses:' lines while ignoring the resolver server address.
  $answersA = @()
  $answersAAAA = @()
  foreach ($type in @('A', 'AAAA')) {
    # Match user-preferred syntax order: nslookup <name> <server> -type=X -timeout=N -retry=1
    $nsArgs = @($Name, $Server, "-type=$type", "-timeout=$TimeoutSec", "-retry=1")
    $output = & nslookup @nsArgs 2>&1
    $inAnswer = $false
    foreach ($line in $output) {
      if (-not $inAnswer) {
        if ($line -match '^(Non-authoritative answer|Answer):' -or $line -match '^\s*Name\s*:' -or $line -match '^\s*Aliases?\s*:') {
          $inAnswer = $true
        }
        continue
      }
      if ($line -match '^\s*Addresses?\s*:\s*(.+)$') {
        $rest = $Matches[1]
        $tokens = ($rest -split '[\s,;]+' | Where-Object { $_ })
        foreach ($t in $tokens) {
          if ($t -eq $Server) { continue }
          if ($type -eq 'A') {
            if ($t -match '^(?:\d{1,3}\.){3}\d{1,3}$') { $answersA += $t }
          }
          else {
            if ($t -match '^[0-9a-fA-F:]+$' -and $t -like '*:*') { $answersAAAA += $t }
          }
        }
      }
      elseif ($line -match '^\s*Address\s*:\s*(.+)$') {
        $t = $Matches[1].Trim()
        if ($t -ne $Server) {
          if ($type -eq 'A') {
            if ($t -match '^(?:\d{1,3}\.){3}\d{1,3}$') { $answersA += $t }
          }
          else {
            if ($t -match '^[0-9a-fA-F:]+$' -and $t -like '*:*') { $answersAAAA += $t }
          }
        }
      }
    }
  }
  [pscustomobject]@{
    A    = @($answersA | Sort-Object -Unique)
    AAAA = @($answersAAAA | Sort-Object -Unique)
    OK   = (($answersA.Count + $answersAAAA.Count) -gt 0)
  }
}

function Get-ReliabilityScore {
  param([string[]]$BaselineA, [string[]]$BaselineAAAA, [string[]]$A, [string[]]$AAAA)
  $exactA    = (@($A)    -join ',') -eq (@($BaselineA)    -join ',')
  $exactAAAA = (@($AAAA) -join ',') -eq (@($BaselineAAAA) -join ',')
  if ($exactA -or $exactAAAA) { return 1.0 }
  if ((@($A).Count + @($AAAA).Count) -gt 0) { return 0.8 }
  return 0.0
}

function Get-RowReliability {
  param([string]$ResolverRaw)
  $tokens = ($ResolverRaw -split '[,;\s]+' | Where-Object { $_ })
  $best = 0.0
  foreach ($ip in $tokens) {
    $ans = Get-DnsAnswersViaNslookup -Server $ip -Name $Domain -TimeoutSec $PerResolverTimeoutSec
    $rel = if ($ans.OK) { Get-ReliabilityScore -BaselineA $baseline.A -BaselineAAAA $baseline.AAAA -A $ans.A -AAAA $ans.AAAA } else { 0.0 }
    if ($rel -gt $best) { $best = $rel }
    if ($best -ge 1.0) { break }
  }
  return $best
}

function Get-DuplicateHeaderMaps {
  param([string]$Path)
  $headerLine = Get-Content -Path $Path -TotalCount 1
  $headersOriginal = ($headerLine -split ',').ForEach({ $_.Trim() })
  $counts = @{}
  $headersRenamed = @()
  foreach ($h in $headersOriginal) {
    if ($counts.ContainsKey($h)) { $counts[$h] += 1; $headersRenamed += ($h + $counts[$h]) }
    else { $counts[$h] = 1; $headersRenamed += $h }
  }
  [pscustomobject]@{ HeadersOriginal=$headersOriginal; HeadersRenamed=$headersRenamed }
}

function Invoke-CsvStreaming {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][bool]$UseLastCheckedAt,
    [Parameter(Mandatory=$true)][string]$Label
  )
  $maps = Get-DuplicateHeaderMaps -Path $Path
  $ren = $maps.HeadersRenamed
  $orig = $maps.HeadersOriginal
  $checkedCols = @($ren | Where-Object { $_ -like 'checked_at*' })
  $checkedColName = if ($checkedCols -and $checkedCols.Count -gt 0) { if ($UseLastCheckedAt) { $checkedCols[-1] } else { $checkedCols[0] } } else { 'checked_at' }

  $tmp = [System.IO.Path]::GetTempFileName()
  # Write original header to temp to preserve duplicate names
  Set-Content -Path $tmp -Value ($orig -join ',') -Encoding UTF8

  $total = (([System.IO.File]::ReadLines($Path) | Measure-Object).Count) - 1
  $index = 0
  foreach ($line in [System.IO.File]::ReadLines($Path) | Select-Object -Skip 1) {
    $index++
    $obj = $line | ConvertFrom-Csv -Header $ren
    $rel = Get-RowReliability -ResolverRaw ([string]$obj.ip_address)
    $obj.reliability = ('{0:F2}' -f [double]$rel)
    $obj.$checkedColName = ([DateTime]::UtcNow).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $row = ($obj | Select-Object -Property $ren | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1)
    Add-Content -Path $tmp -Value $row -Encoding UTF8
    $pct = if ($total -gt 0) { [int](($index / $total) * 100) } else { 0 }
    Write-Progress -Activity ('{0} streaming...' -f $Label) -Status ("{0}/{1}" -f $index,$total) -PercentComplete $pct
  }
  Write-Progress -Activity ('{0} streaming...' -f $Label) -Completed
  Move-Item -Force -Path $tmp -Destination $Path
}

Write-Host ('Baselining {0} via {1} ...' -f $Domain, $BaselineServer)
$baseline = [pscustomobject]@{ A = @(); AAAA = @(); OK = $true }
try {
  $baseline.A = (
    Resolve-DnsName -Server $BaselineServer -Name $Domain -Type A -DnsOnly -NoHostsFile -QuickTimeout -ErrorAction Stop |
    Where-Object { $_.Type -eq 'A' } |
    Select-Object -ExpandProperty IPAddress
  ) | Sort-Object -Unique
}
catch { $baseline.OK = $false }
try {
  $baseline.AAAA = (
    Resolve-DnsName -Server $BaselineServer -Name $Domain -Type AAAA -DnsOnly -NoHostsFile -QuickTimeout -ErrorAction Stop |
    Where-Object { $_.Type -eq 'AAAA' } |
    Select-Object -ExpandProperty IPAddress
  ) | Sort-Object -Unique
}
catch { if ($baseline.A.Count -eq 0) { $baseline.OK = $false } }
Write-Host ('Baseline A:    {0}' -f ($baseline.A -join ', '))
Write-Host ('Baseline AAAA: {0}' -f ($baseline.AAAA -join ', '))

# --- Load CSVs ---
$ipv4 = @()
$ipv6 = @()

function Import-CsvWithDuplicateHeaders {
  param([Parameter(Mandatory = $true)][string]$Path)
  $lines = Get-Content -Path $Path -ErrorAction Stop
  if (-not $lines -or $lines.Count -lt 2) { return [pscustomobject]@{ Rows = @(); HeadersOriginal = @(); HeadersRenamed = @() } }
  $headersOriginal = ($lines[0] -split ',').ForEach({ $_.Trim() })
  $counts = @{}
  $headersRenamed = @()
  foreach ($h in $headersOriginal) {
    if ($counts.ContainsKey($h)) {
      $counts[$h] += 1
      $headersRenamed += ($h + $counts[$h])
    }
    else {
      $counts[$h] = 1
      $headersRenamed += $h
    }
  }
  $dataLines = $lines[1..($lines.Length - 1)]
  $rows = $dataLines | ConvertFrom-Csv -Header $headersRenamed
  [pscustomobject]@{ Rows = $rows; HeadersOriginal = $headersOriginal; HeadersRenamed = $headersRenamed }
}

$csv4 = $null
$csv6 = $null
if ($IPv4Path) { $csv4 = Import-CsvWithDuplicateHeaders -Path $IPv4Path; $ipv4 = $csv4.Rows }
if ($IPv6Path) { $csv6 = Import-CsvWithDuplicateHeaders -Path $IPv6Path; $ipv6 = $csv6.Rows }

foreach ($t in @($ipv4, $ipv6)) {
  if ($t -and $t.Count -gt 0) {
    if (-not ($t[0].PSObject.Properties.Name -contains 'ip_address')) {
      throw "Column 'ip_address' missing in CSV."
    }
    if (-not ($t[0].PSObject.Properties.Name -contains 'reliability')) {
      foreach ($row in $t) { $row | Add-Member -NotePropertyName reliability -NotePropertyValue 1 -Force }
    }
    # Ensure at least one checked_at column exists
    $checkedCols = $t[0].PSObject.Properties.Name | Where-Object { $_ -like 'checked_at*' }
    if (-not $checkedCols -or $checkedCols.Count -eq 0) {
      foreach ($row in $t) { $row | Add-Member -NotePropertyName checked_at -NotePropertyValue '' -Force }
    }
  }
}

# Determine which checked_at column to use per table
function Get-CheckedAtColumnName {
  param([object]$FirstRow, [bool]$UseLast)
  $cols = $FirstRow.PSObject.Properties.Name | Where-Object { $_ -like 'checked_at*' }
  if (-not $cols -or $cols.Count -eq 0) { return 'checked_at' }
  if ($UseLast) {
    return $cols[-1]
  }
  else {
    return $cols[0]
  }
}

$ipv4CheckedCol = if ($ipv4 -and $ipv4.Count -gt 0) { Get-CheckedAtColumnName -FirstRow $ipv4[0] -UseLast:$false } else { 'checked_at' }
$ipv6CheckedCol = if ($ipv6 -and $ipv6.Count -gt 0) { Get-CheckedAtColumnName -FirstRow $ipv6[0] -UseLast:$true } else { 'checked_at' }

# Build work list (table ref + row)
$work = @()
if ($ipv4) { $work += $ipv4 | ForEach-Object { [pscustomobject]@{ Table = 'IPv4'; Row = $_ } } }
if ($ipv6) { $work += $ipv6 | ForEach-Object { [pscustomobject]@{ Table = 'IPv6'; Row = $_ } } }

$nowIso = ([DateTime]::UtcNow).ToString('yyyy-MM-ddTHH:mm:ssZ')

# --- Progress setup ---
$total = $work.Count
if ($total -eq 0) { Write-Warning 'No rows to process.'; return }
$ipv4Count = if ($null -ne $ipv4) { try { ($ipv4 | Measure-Object).Count } catch { 0 } } else { 0 }
$ipv6Count = if ($null -ne $ipv6) { try { ($ipv6 | Measure-Object).Count } catch { 0 } } else { 0 }
$modeLabel = if ($LowResourceMode) { 'streaming' } else { 'parallel' }
$null = Write-Host ("Starting {0} checks across IPv4:{1} IPv6:{2} (mode: {3})" -f $total, $ipv4Count, $ipv6Count, $modeLabel)
$null = Write-Progress -Activity 'DNS checks running...' -Status ("Starting {0} checks…" -f $total) -PercentComplete 0
$statusFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ("resolver_status_{0}.log" -f ([guid]::NewGuid())))
New-Item -ItemType File -Path $statusFile -Force | Out-Null
$startTime = Get-Date
$progressTimer = [System.Timers.Timer]::new(500)
$processed = 0
$progressTimer.add_Elapsed({
    try {
      if (Test-Path $statusFile) {
        $processed = (Get-Content -Path $statusFile -ReadCount 0 -ErrorAction Stop).Count
        $elapsed = (Get-Date) - $startTime
        $rate = if ($elapsed.TotalSeconds -gt 0) { [math]::Round($processed / $elapsed.TotalSeconds, 1) } else { 0 }
        $pct = [int](([double]$processed / [double]$using:total) * 100)
        $remaining = if ($rate -gt 0) { [TimeSpan]::FromSeconds([math]::Max(0, ($using:total - $processed) / $rate)) } else { [TimeSpan]::FromSeconds(0) }
        Write-Progress -Activity 'DNS checks running...' -Status ("{0}/{1} processed | {2}/s | Elapsed {3:hh\:mm\:ss} | ETA {4:hh\:mm\:ss}" -f $processed, $using:total, $rate, $elapsed, $remaining) -PercentComplete $pct
      }
    }
    catch { }
  })
$progressTimer.Start()

# Low-resource streaming path: process each CSV sequentially and update per-row
if ($LowResourceMode) {
  if ($IPv4Path) { Invoke-CsvStreaming -Path $IPv4Path -UseLastCheckedAt:$false -Label 'IPv4' }
  if ($IPv6Path) { Invoke-CsvStreaming -Path $IPv6Path -UseLastCheckedAt:$true -Label 'IPv6' }
  $progressTimer.Stop(); $progressTimer.Dispose()
  Write-Progress -Activity 'DNS checks running...' -Completed
  Write-Host 'Summary: streaming mode completed.'
  if ($IPv4Path) { Write-Host ("Updated IPv4 CSV: {0}" -f $IPv4Path) }
  if ($IPv6Path) { Write-Host ("Updated IPv6 CSV: {0}" -f $IPv6Path) }
  return
}

# --- Check all resolvers in parallel ---
$results = $work | ForEach-Object -Parallel {
  function Get-DnsAnswersViaNslookupLocal {
    param([string]$Server, [string]$Name, [int]$TimeoutSec)
    $answersA = @(); $answersAAAA = @();
    foreach ($type in @('A', 'AAAA')) {
      $nsArgs = @($Name, $Server, "-type=$type", "-timeout=$TimeoutSec", "-retry=1")
      $output = & nslookup @nsArgs 2>&1
      $inAnswer = $false
      foreach ($line in $output) {
        if (-not $inAnswer) {
          if ($line -match '^(Non-authoritative answer|Answer):' -or $line -match '^\s*Name\s*:' -or $line -match '^\s*Aliases?\s*:') { $inAnswer = $true }
          continue
        }
        if ($line -match '^\s*Addresses?\s*:\s*(.+)$') {
          $rest = $Matches[1]
          $tokens = ($rest -split '[\s,;]+' | Where-Object { $_ })
          foreach ($t in $tokens) {
            if ($t -eq $Server) { continue }
            if ($type -eq 'A') {
              if ($t -match '^(?:\d{1,3}\.){3}\d{1,3}$') { $answersA += $t }
            }
            else {
              if ($t -match '^[0-9a-fA-F:]+$' -and $t -like '*:*') { $answersAAAA += $t }
            }
          }
        }
        elseif ($line -match '^\s*Address\s*:\s*(.+)$') {
          $t = $Matches[1].Trim()
          if ($t -ne $Server) {
            if ($type -eq 'A') {
              if ($t -match '^(?:\d{1,3}\.){3}\d{1,3}$') { $answersA += $t }
            }
            else {
              if ($t -match '^[0-9a-fA-F:]+$' -and $t -like '*:*') { $answersAAAA += $t }
            }
          }
        }
      }
    }
    [pscustomobject]@{ A = @($answersA | Sort-Object -Unique); AAAA = @($answersAAAA | Sort-Object -Unique); OK = (($answersA.Count + $answersAAAA.Count) -gt 0) }
  }

  function GetReliabilityLocal {
    param([string[]]$BaselineA, [string[]]$BaselineAAAA, [string[]]$A, [string[]]$AAAA)
    $exactA = (@($A) -join ',') -eq (@($BaselineA) -join ',')
    $exactAAAA = (@($AAAA) -join ',') -eq (@($BaselineAAAA) -join ',')
    if ($exactA -or $exactAAAA) { return 1.0 }
    if ((@($A).Count + @($AAAA).Count) -gt 0) { return 0.8 }
    return 0.0
  }

  $row = $_.Row
  $resolverRaw = [string]$row.ip_address
  $tokens = ($resolverRaw -split '[,;\s]+' | Where-Object { $_ })
  $bestReliability = 0.0
  foreach ($ip in $tokens) {
    $ans = Get-DnsAnswersViaNslookupLocal -Server $ip -Name $using:Domain -TimeoutSec $using:PerResolverTimeoutSec
    $rel = if ($ans.OK) { GetReliabilityLocal -BaselineA $using:baseline.A -BaselineAAAA $using:baseline.AAAA -A $ans.A -AAAA $ans.AAAA } else { 0.0 }
    if ($rel -gt $bestReliability) { $bestReliability = $rel }
    if ($bestReliability -ge 1.0) { break }
  }

  # Signal progress (one line per item)
  Add-Content -Path $using:statusFile -Value 'ok'

  [pscustomobject]@{ Table = $_.Table; Resolver = $resolverRaw; Reliability = $bestReliability }
} -ThrottleLimit $ThrottleLimit

# --- Stop & clear progress ---
$progressTimer.Stop(); $progressTimer.Dispose()
Write-Progress -Activity 'DNS checks running...' -Completed
Remove-Item -Path $statusFile -Force -ErrorAction SilentlyContinue

# --- Apply updates ---
foreach ($r in $results) {
  if ($r.Table -eq 'IPv4') {
    $targets = $ipv4 | Where-Object { $_.ip_address -eq $r.Resolver }
    foreach ($row in $targets) {
      $row.reliability = ('{0:F2}' -f [double]$r.Reliability)
      $row.$ipv4CheckedCol = $nowIso
    }
  }
  else {
    $targets = $ipv6 | Where-Object { $_.ip_address -eq $r.Resolver }
    foreach ($row in $targets) {
      $row.reliability = ('{0:F2}' -f [double]$r.Reliability)
      $row.$ipv6CheckedCol = $nowIso
    }
  }
}

# --- Write back CSVs ---
if ($IPv4Path -and $ipv4 -and $ipv4.Count -gt 0) {
  $select4 = $csv4.HeadersRenamed
  $ipv4 | Select-Object -Property $select4 | Export-Csv -Path $IPv4Path -NoTypeInformation -Encoding UTF8
  # Restore original header line to preserve duplicate names
  $tmp = Get-Content -Path $IPv4Path
  $tmp[0] = ($csv4.HeadersOriginal -join ',')
  Set-Content -Path $IPv4Path -Value $tmp -Encoding UTF8
}
if ($IPv6Path -and $ipv6 -and $ipv6.Count -gt 0) {
  $select6 = $csv6.HeadersRenamed
  $ipv6 | Select-Object -Property $select6 | Export-Csv -Path $IPv6Path -NoTypeInformation -Encoding UTF8
  $tmp = Get-Content -Path $IPv6Path
  $tmp[0] = ($csv6.HeadersOriginal -join ',')
  Set-Content -Path $IPv6Path -Value $tmp -Encoding UTF8
}

# --- Final summary ---
$fullMatches = ($results | Where-Object { [double]$_.Reliability -ge 1.0 }).Count
$partial = ($results | Where-Object { [double]$_.Reliability -ge 0.8 -and [double]$_.Reliability -lt 1.0 }).Count
$fail = ($results | Where-Object { [double]$_.Reliability -lt 0.8 }).Count
Write-Host ("Summary: {0} exact, {1} answered, {2} no answer" -f $fullMatches, $partial, $fail)
if ($IPv4Path) { Write-Host ("Updated IPv4 CSV: {0}" -f $IPv4Path) }
if ($IPv6Path) { Write-Host ("Updated IPv6 CSV: {0}" -f $IPv6Path) }


 
