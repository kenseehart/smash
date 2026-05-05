#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Repo = 'kenseehart/smash'
$Ref = if ($env:SMASH_REF) { $env:SMASH_REF } else { 'main' }
$Prefix = if ($env:SMASH_PREFIX) { $env:SMASH_PREFIX } else { Join-Path $env:USERPROFILE '.local' }
$ShareDir = Join-Path $Prefix 'share\smash'
$BinDir = Join-Path $Prefix 'bin'
$VenvDir = Join-Path $ShareDir '.venv'
$TarballUrl = "https://github.com/$Repo/archive/$Ref.tar.gz"

New-Item -ItemType Directory -Force -Path $ShareDir, $BinDir | Out-Null

$ScriptPath = $MyInvocation.MyCommand.Path
$LocalSrc = $null
if ($ScriptPath) {
    $sd = Split-Path -Parent $ScriptPath
    if ((Test-Path (Join-Path $sd 'smash.py')) -and (Test-Path (Join-Path $sd 'smash.png'))) {
        $LocalSrc = $sd
    }
}
if ($LocalSrc) {
    Write-Host ">> using local payload from $LocalSrc"
    $SrcDir = $LocalSrc
} else {
    Write-Host ">> downloading $TarballUrl"
    $Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("smash-" + [System.Guid]::NewGuid())
    New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
    $Tarball = Join-Path $Tmp 'smash.tar.gz'
    Invoke-WebRequest -Uri $TarballUrl -OutFile $Tarball -UseBasicParsing
    & tar -xzf $Tarball -C $Tmp --strip-components=1
    if ($LASTEXITCODE -ne 0) { throw "tar extract failed (exit $LASTEXITCODE); needs Windows 10 1803+ for built-in tar" }
    Remove-Item $Tarball -Force
    $SrcDir = $Tmp
}

Copy-Item (Join-Path $SrcDir 'smash.py')  (Join-Path $ShareDir 'smash.py')  -Force
Copy-Item (Join-Path $SrcDir 'smash.png') (Join-Path $ShareDir 'smash.png') -Force

function Ensure-Uv {
    $LocalBin = Join-Path $env:USERPROFILE '.local\bin'
    $env:Path = "$LocalBin;$env:Path"
    if (Get-Command uv -ErrorAction SilentlyContinue) { return }
    Write-Host ">> installing uv (sandboxed, no admin)..."
    powershell -NoProfile -ExecutionPolicy Bypass -Command "iwr https://astral.sh/uv/install.ps1 -UseBasicParsing | iex"
    $env:Path = "$LocalBin;$env:Path"
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) { throw "failed to install uv" }
}

function Test-Tkinter([string]$py) {
    if (-not $py) { return $false }
    if (-not (Get-Command $py -ErrorAction SilentlyContinue)) { return $false }
    & $py -c "import tkinter" 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Pick-Python {
    $candidates = @()
    if ($env:SMASH_PYTHON) { $candidates += $env:SMASH_PYTHON }
    $candidates += @('python', 'python3', 'py')
    foreach ($c in $candidates) {
        if (Test-Tkinter $c) {
            return (Get-Command $c -ErrorAction SilentlyContinue).Source
        }
    }
    Write-Host ">> no system python has tkinter; falling back to uv-managed cpython"
    Ensure-Uv
    Write-Host ">> installing managed cpython 3.12 via uv..."
    & uv python install 3.12
    if ($LASTEXITCODE -ne 0) { throw "uv python install failed" }
    $managed = Join-Path $env:USERPROFILE '.local\bin\python3.12.exe'
    if (-not (Test-Path $managed)) {
        $managed = (& uv python find 3.12 | Select-Object -First 1)
    }
    if (Test-Tkinter $managed) { return $managed }
    throw "uv-managed python at $managed lacks tkinter"
}

$Py = Pick-Python
Write-Host ">> base python: $Py"

Ensure-Uv

Write-Host ">> creating venv at $VenvDir"
if (Test-Path $VenvDir) { Remove-Item -Recurse -Force $VenvDir }
& uv venv --quiet --python $Py $VenvDir
if ($LASTEXITCODE -ne 0) { throw "uv venv failed" }

Write-Host ">> installing mss + Pillow into venv"
$VenvPy = Join-Path $VenvDir 'Scripts\python.exe'
& uv pip install --quiet --python $VenvPy mss Pillow
if ($LASTEXITCODE -ne 0) { throw "uv pip install failed" }

& $VenvPy -c "import tkinter, mss, PIL.Image, PIL.ImageTk"
if ($LASTEXITCODE -ne 0) { throw "verification failed" }
Write-Host ">> verified: tkinter + mss + Pillow available"

$WrapperPath = Join-Path $BinDir 'smash.cmd'
$WrapperContent = "@echo off`r`n`"$VenvPy`" `"$(Join-Path $ShareDir 'smash.py')`" %*`r`n"
[System.IO.File]::WriteAllText($WrapperPath, $WrapperContent)

Write-Host ">> installed:"
Write-Host "   $ShareDir\smash.py"
Write-Host "   $ShareDir\smash.png"
Write-Host "   $VenvDir\  (mss, Pillow)"
Write-Host "   $WrapperPath"

if (";$env:Path;" -notlike "*;$BinDir;*") {
    Write-Host ">> NOTE: $BinDir is not on `$env:Path; add it (User PATH) to use 'smash' directly."
}
