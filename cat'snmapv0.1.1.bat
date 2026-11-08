@echo off
setlocal EnableDelayedExpansion
title cat's nmap 0.1.2  [batch clone]
color 0B

set "VERSION=0.1.2"
set "SCRIPTDIR=%~dp0"
set "PS1=%TEMP%\cnm_%RANDOM%%RANDOM%.ps1"
set "ARGF=%TEMP%\cnm_%RANDOM%%RANDOM%.arg"

where powershell >nul 2>&1 || (echo [!] powershell missing & pause & exit /b 1)

set "OUTDIR=%SCRIPTDIR%scans"
mkdir "%OUTDIR%" >nul 2>&1
if not exist "%OUTDIR%" (
  set "OUTDIR=%LOCALAPPDATA%\cat-snmap\scans"
  mkdir "!OUTDIR!" >nul 2>&1
)
if not exist "%OUTDIR%" (echo [!] cannot create output dir & pause & exit /b 1)

set "TOP100=7,9,13,21,22,23,25,26,37,53,79,80,81,82,83,84,85,88,89,99,100,106,109,110,111,113,119,125,135,139,143,144,146,161,162,163,179,199,211,212,222,254,255,256,259,264,280,301,306,311,340,366,389,406,407,416,417,425,427,443,444,445,458,464,465,481,497,500,512,513,514,515,524,541,543,544,545,548,554,555,563,587,593,616,617,625,631,636,646,648,666,667,668,683,687,691,700,705,711,714,720,722,726,749,765,777,783,787,800,801,808,843,873,880,888,898,900,901,902,903,911,912,981,987,990,992,993,995,999,1000,1025,1026,1027,1028,1029,1080,1194,1433,1521,1723,1755,1900,2000,2049,2121,2222,2323,2375,2376,3000,3128,3260,3306,3389,4000,4443,4567,5000,5060,5432,5555,5601,5672,5900,5985,6000,6379,6443,6667,7001,7070,8000,8008,8080,8081,8443,8888,9000,9090,9200,9300,9443,10000,11211,27017,27018,50000,50070"

if not "%~1"=="" goto :parse

:menu
cls
echo ==========================================================
echo               c a t ' s   n m a p   !VERSION!
echo           pure batch clone - no nmap.exe required
echo ==========================================================
echo.
echo   [1] Quick           top 100 TCP ports
echo   [2] Full TCP        1-65535, slow
echo   [3] Service         top 100 + banner grab
echo   [4] OS guess        top 100 + TTL fingerprint
echo   [5] Discovery only  is it up?
echo   [6] Stealth-ish     top 100, 1 worker, long timeout
echo   [7] Custom ports
echo   [q] Quit
echo.
set "KEY="
set /p "KEY=Profile: "
if /i "!KEY!"=="q" goto :eof
set "TARGET="
if "!KEY!"=="7" goto :menucustom
set /p "TARGET=Target (IP or hostname): "
if not defined TARGET goto menu
goto :preset

:menucustom
set /p "TARGET=Target: "
if not defined TARGET goto menu
set /p "PORTSPEC=Ports (e.g. 22,80,100-200): "
if not defined PORTSPEC goto menu
set "KEY=7"
goto :preset

:parse
set "TARGET=%~1"
set "PORTSPEC="
set "TIMEOUT=800"
set "CONC=200"
set "GRAB="
set "OSGUESS="
set "FORCE="
set "ONLYDISC="
set "KEY="
shift
:argloop
set "A=%~1"
if "!A!"=="" goto :argdone
if /i "!A!"=="-p"       (set "PORTSPEC=%~2" & shift & shift & goto :argloop)
if /i "!A!"=="-sV"      (set "GRAB=1" & shift & goto :argloop)
if /i "!A!"=="-O"       (set "OSGUESS=1" & shift & goto :argloop)
if /i "!A!"=="-Pn"      (set "FORCE=1" & shift & goto :argloop)
if /i "!A!"=="-sn"      (set "ONLYDISC=1" & shift & goto :argloop)
if /i "!A!"=="-T2"      (set "TIMEOUT=2000" & set "CONC=25" & shift & goto :argloop)
if /i "!A!"=="-T4"      (set "TIMEOUT=800" & set "CONC=200" & shift & goto :argloop)
if /i "!A!"=="-T5"      (set "TIMEOUT=300" & set "CONC=500" & shift & goto :argloop)
if /i "!A!"=="-h"       goto :help
echo  [?] ignored: !A!
shift
goto :argloop
:argdone
if not defined PORTSPEC set "PORTSPEC=!TOP100!"
goto :run

:help
echo.
echo   usage: %~nx0 ^<target^> [options]
echo.
echo     -p ^<ports^>   port list, ranges ok (22,80,100-200)
echo     -sV          banner grab
echo     -O           TTL os guess
echo     -Pn          force scan, skip up-check
echo     -sn          discovery only
echo     -T2/-T4/-T5  timing profile
echo.
pause
goto :eof

:preset
if "!KEY!"=="1" set "PORTSPEC=!TOP100!" & set "TIMEOUT=800" & set "CONC=200"
if "!KEY!"=="2" set "PORTSPEC=1-65535" & set "TIMEOUT=800" & set "CONC=200"
if "!KEY!"=="3" set "PORTSPEC=!TOP100!" & set "TIMEOUT=800" & set "CONC=200" & set "GRAB=1"
if "!KEY!"=="4" set "PORTSPEC=!TOP100!" & set "TIMEOUT=800" & set "CONC=200" & set "OSGUESS=1"
if "!KEY!"=="5" set "PORTSPEC=!TOP100!" & set "ONLYDISC=1"
if "!KEY!"=="6" set "PORTSPEC=!TOP100!" & set "TIMEOUT=2500" & set "CONC=1"
echo.
choice /c yn /n /m "Force scan even if ICMP is blocked? [y/N] "
if errorlevel 2 (set "FORCE=") else (set "FORCE=1")

:run
set "SAFE=!TARGET!"
set "SAFE=!SAFE::=-!"
set "SAFE=!SAFE:.=_!"
set "SAFE=!SAFE:\=-!"
set "SAFE=!SAFE:/=-!"
set "SAFE=!SAFE: =-!"
set "SAFE=!SAFE:&=-!"
set "SAFE=!SAFE:%%=-!"
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "STAMP=%%I"
set "OUT=%OUTDIR%\!STAMP!_!SAFE!"

for /f "delims=:" %%L in ('findstr /n /b /c:"::PSBEGIN" "%~f0"') do set "N=%%L"
more +!N! "%~f0" > "%PS1%" 2>nul
if not exist "%PS1%" (echo [!] engine extract failed & pause & exit /b 1)

setlocal DisableDelayedExpansion
> "%ARGF%" echo %TARGET%
>> "%ARGF%" echo %PORTSPEC%
endlocal

set "PARGS=-TargetFile "%ARGF%" -Timeout !TIMEOUT! -Conc !CONC! -OutBase "!OUT!""
if defined GRAB set "PARGS=!PARGS! -Banner"
if defined OSGUESS set "PARGS=!PARGS! -OsGuess"
if defined FORCE set "PARGS=!PARGS! -Pn"
if defined ONLYDISC set "PARGS=!PARGS! -DiscoveryOnly"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" !PARGS!
set "RC=%ERRORLEVEL%"
del "%PS1%" >nul 2>&1
del "%ARGF%" >nul 2>&1

if !RC!==2 goto :eof
echo.
choice /c yn /n /m "Open output folder? [y/n] "
if errorlevel 2 goto :eof
start "" "%OUTDIR%"
goto :eof

exit /b 0
::PSBEGIN
param(
  [string]$TargetFile,
  [string]$Target = "",
  [string]$Ports = "",
  [int]$Timeout = 800,
  [int]$Conc = 200,
  [switch]$Pn,
  [switch]$Banner,
  [switch]$OsGuess,
  [switch]$DiscoveryOnly,
  [string]$OutBase = ""
)
$ErrorActionPreference = 'SilentlyContinue'

if ($TargetFile) {
  $lines = @(Get-Content -LiteralPath $TargetFile -TotalCount 2 -ErrorAction SilentlyContinue)
  if (-not $Target) { $Target = "$($lines[0])".Trim() }
  if (-not $Ports)  { $Ports  = "$($lines[1])".Trim() }
}

$rep = [System.Collections.Generic.List[string]]::new()
$lock = [object]::new()
function Say($s) { Write-Host $s; $rep.Add($s) }

$t0 = Get-Date
$ip = $null
try { $ip = ([Net.Dns]::GetHostAddresses($Target) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1) } catch {}
if (-not $ip) { try { $ip = [ipaddress]::Parse($Target) } catch {} }
if (-not $ip) { Say "[!] cannot resolve $Target"; exit 2 }
$ip = $ip.ToString()
$ipep = [Net.IPEndPoint]::new([ipaddress]::Parse($ip), 0)

$ptr = "n/a"
try { $ptr = [Net.Dns]::GetHostEntry($ip).HostName } catch {}
$mac = ""
foreach ($l in (& arp -a 2>$null)) { if ($l -match [regex]::Escape($ip)) { if ($l -match '([0-9a-fA-F]{2}[-:]){5}[0-9a-fA-F]{2}') { $mac = $Matches[0]; break } } }

function Get-Ttl($h) {
  $o = (& ping -n 1 -w 1500 $h 2>$null | Out-String)
  if ($o -match 'TTL=(\d+)') { return [int]$Matches[1] }
  return -1
}
function Guess-Os($t) {
  if ($t -lt 0) { return "unknown" }
  if ($t -le 32) { return "embedded/network gear" }
  if ($t -le 64) { return "Linux/Unix-like" }
  if ($t -le 128) { return "Windows-like" }
  return "network device"
}

$ttl = -1
$alive = $false
if (-not $Pn) {
  $ttl = Get-Ttl $ip
  $alive = ($ttl -ge 0)
  if (-not $alive) {
    foreach ($p in 80,443,22,445) {
      $s = [Net.Sockets.Socket]::new('InterNetwork','Stream','Tcp')
      try {
        $ar = $s.BeginConnect($ip,$p,$null,$null)
        if ($ar.AsyncWaitHandle.WaitOne(700)) { $s.EndConnect($ar); $alive = $true; break }
      } catch {} finally { $s.Close() }
    }
  }
}

Say "starting cat's nmap $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
Say "target   : $Target"
Say "resolved : $ip"
Say "ptr      : $ptr"
if ($mac) { Say "mac      : $mac" }
if (-not $Pn) { Say "ttl      : $(if($ttl -ge 0){$ttl}else{'none (icmp filtered)'})" }
if ($OsGuess) { Say "os guess : $(Guess-Os $ttl)" }
Say "alive    : $(if($Pn){'forced'}elseif($alive){'yes'}else{'no'})"
Say ""

if (-not $alive -and -not $Pn) { Say "[!] host looks down. retry with -Pn." }
if ($DiscoveryOnly) {
  Say "discovery only, no port scan."
  if ($OutBase) { $rep -join "`r`n" | Set-Content "$OutBase.txt" }
  exit 0
}

$set = [System.Collections.Generic.SortedSet[int]]::new()
foreach ($ch in $Ports.Split(',')) {
  $ch = $ch.Trim()
  if ($ch -match '^(\d+)\s*-\s*(\d+)$') {
    $a = [int]$Matches[1]; $b = [int]$Matches[2]
    if ($a -gt $b) { $t = $a; $a = $b; $b = $t }
    for ($i = $a; $i -le $b; $i++) { if ($i -ge 1 -and $i -le 65535) { [void]$set.Add($i) } }
  } elseif ($ch -match '^\d+$') {
    $v = [int]$ch; if ($v -ge 1 -and $v -le 65535) { [void]$set.Add($v) }
  }
}
if ($set.Count -eq 0) { Say "[!] empty port list"; exit 2 }
$ports = @($set)
$total = $ports.Count

$httpProbe = [Text.Encoding]::ASCII.GetBytes("HEAD / HTTP/1.0`r`nHost: $ip`r`nUser-Agent: cat-snmap/$VERSION`r`n`r`n")
$lineProbe = [Text.Encoding]::ASCII.GetBytes("`r`n")

$probes = @{}
foreach ($hp in 80,81,82,83,84,85,88,800,801,808,880,888,900,901,902,903,911,912,981,987,990,992,1000,3000,3128,5000,5601,7001,7070,8000,8008,8080,8081,8888,9000,9090,9200,9300,10000,2375,50070) { $probes[$hp] = $httpProbe }
foreach ($lp in 21,23,25,110,119,143,587,6667,666,667,668) { $probes[$lp] = $lineProbe }
$probes[6379]  = [Text.Encoding]::ASCII.GetBytes("PING`r`n")
$probes[11211] = [Text.Encoding]::ASCII.GetBytes("version`r`n")
$tls = @{}
foreach ($tp in 443,465,993,995,4443,8443,9443,6443) { $tls[$tp] = 1 }

$workers = [math]::Min($Conc, $total)
Say "scanning $total TCP ports, timeout ${Timeout}ms, $workers workers"
Say ""

$q = [System.Collections.Concurrent.ConcurrentQueue[int]]::new()
foreach ($p in $ports) { $q.Enqueue($p) }
$bag = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
$prog = [hashtable]::Synchronized(@{ Done = 0 })

$work = {
  param($q, $ip, $ipep, $timeout, $bag, $grab, $probes, $tls, $lock, $prog, $total)
  [int]$p = 0
  while ($q.TryDequeue([ref]$p)) {
    $ipep.Port = $p
    $s = [Net.Sockets.Socket]::new('InterNetwork','Stream','Tcp')
    try {
      $ar = $s.BeginConnect($ipep, $null, $null)
      if ($ar.AsyncWaitHandle.WaitOne($timeout)) {
        $s.EndConnect($ar)
        $bn = ""
        if ($grab) {
          try {
            if ($probes.ContainsKey($p)) { [void]$s.Send($probes[$p]) }
            $s.ReceiveTimeout = if ($tls.ContainsKey($p)) { 250 } else { 800 }
            $buf = New-Object byte[] 512
            $n = $s.Receive($buf)
            if ($n -gt 0) { $bn = ([Text.Encoding]::ASCII.GetString($buf, 0, $n) -replace '[^\x20-\x7E]', '.').Trim() }
          } catch {}
        }
        $bag.Add([pscustomobject]@{ Port = $p; Banner = $bn })
        [System.Threading.Monitor]::Enter($lock)
        try { Write-Host ("  + {0,-6} open {1}" -f "$p/tcp", $bn) } finally { [System.Threading.Monitor]::Exit($lock) }
      }
    } catch {} finally { $s.Close() }
    $prog.Done++
  }
}

$pool = [runspacefactory]::CreateRunspacePool(1, $workers)
$pool.Open()
$jobs = @()
$script = $work.ToString()
for ($i = 0; $i -lt $workers; $i++) {
  $ps = [powershell]::Create()
  $ps.RunspacePool = $pool
  [void]$ps.AddScript($script).AddArgument($q).AddArgument($ip).AddArgument($ipep).AddArgument($Timeout).AddArgument($bag).AddArgument([bool]$Banner).AddArgument($probes).AddArgument($tls).AddArgument($lock).AddArgument($prog).AddArgument($total)
  $jobs += [pscustomobject]@{ P = $ps; H = $ps.BeginInvoke() }
}
$handles = @($jobs | ForEach-Object { $_.H.AsyncWaitHandle })
while ($true) {
  $idx = [System.Threading.WaitHandle]::WaitAny($handles, 3000)
  if ($idx -ge 0) { break }
  $d = $prog.Done
  $pct = if ($total) { [math]::Round(100 * $d / $total, 1) } else { 0 }
  Write-Host ("  . progress {0}/{1} ({2}%)" -f $d, $total, $pct)
}
foreach ($j in $jobs) { try { [void]$j.P.EndInvoke($j.H) } catch {}; $j.P.Dispose() }
$pool.Close()

$svc = @{ 21='ftp';22='ssh';23='telnet';25='smtp';53='domain';80='http';110='pop3';111='rpcbind';135='msrpc';137='netbios-ns';139='netbios-ssn';143='imap';161='snmp';389='ldap';443='https';445='microsoft-ds';465='smtps';514='syslog';587='submission';631='ipp';636='ldaps';873='rsync';993='imaps';995='pop3s';1080='socks';1433='ms-sql';1521='oracle';2049='nfs';2375='docker';3000='http-alt';3306='mysql';3389='ms-wbt';5432='postgresql';5601='kibana';5900='vnc';5985='winrm';6379='redis';6443='k8s-api';8080='http-alt';8443='https-alt';9200='elastic';11211='memcached';27017='mongodb' }

$res = @($bag | Sort-Object Port)
Say ""
Say ("{0,-10} {1,-6} {2,-14} {3}" -f "PORT","STATE","SERVICE","BANNER")
Say ("{0,-10} {1,-6} {2,-14} {3}" -f "----","-----","-------","------")
foreach ($r in $res) {
  $name = if ($svc.ContainsKey($r.Port)) { $svc[$r.Port] } else { "unknown" }
  Say ("{0,-10} {1,-6} {2,-14} {3}" -f "$($r.Port)/tcp", "open", $name, $r.Banner)
}
$dur = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
Say ""
Say "open ports: $($res.Count) of $total scanned in ${dur}s"

if ($OutBase) {
  $rep -join "`r`n" | Set-Content "$OutBase.txt"
  $csv = @("port,state,service,banner") + ($res | ForEach-Object { $n = if ($svc.ContainsKey($_.Port)) { $svc[$_.Port] } else { 'unknown' }; "$($_.Port),open,$n,$($_.Banner -replace ',',';')" })
  $csv | Set-Content "$OutBase.csv"
  Write-Host ""
  Write-Host "saved: $OutBase.txt"
  Write-Host "saved: $OutBase.csv"
}
exit $(if ($res.Count) { 0 } else { 1 })
