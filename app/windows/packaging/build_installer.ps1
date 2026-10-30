<#
.SYNOPSIS
    Builds Rupayan SiteSync Windows release and generates the Inno Setup installer.
.DESCRIPTION
    This script automates building the Flutter Windows release and compiling the
    Inno Setup package locally.
#>

[CmdletBinding()]
param(
    [string]$Version,
    [switch]$OpenFolder
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Resolve-Path "$scriptDir\..\.."
Set-Location $appDir

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Rupayan SiteSync - Local Windows Installer Builder   " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Working Directory: $appDir"

# 1. Verify Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter SDK not found in PATH! Please ensure Flutter is installed and in your environment PATH."
}

# 2. Extract Version if not provided
if (-not $Version) {
    if (Test-Path "pubspec.yaml") {
        $pubspec = Get-Content "pubspec.yaml" -Raw
        if ($pubspec -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
            $Version = $matches[1]
        }
    }
    if (-not $Version) { $Version = "1.0.0" }
}
Write-Host "Building version: $Version" -ForegroundColor Green

# 3. Flutter steps
Write-Host "`n[1/4] Configuring Flutter..." -ForegroundColor Yellow
flutter config --enable-windows-desktop

Write-Host "`n[2/4] Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n[3/4] Compiling Windows release binary..." -ForegroundColor Yellow
flutter build windows --release --build-name=$Version

$exePath = "build\windows\x64\runner\Release\rupayan.exe"
if (-not (Test-Path $exePath)) {
    Write-Error "Release executable not found at: $exePath"
}
Write-Host "Release binary verified at: $exePath" -ForegroundColor Green

# 4. Inno Setup Compiler detection
Write-Host "`n[4/4] Locating Inno Setup 6..." -ForegroundColor Yellow
$iscc = (Get-Command ISCC.exe -ErrorAction SilentlyContinue)?.Source
if (-not $iscc) {
    $searchPaths = @(
        "$env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "$env:LocalAppData\Programs\Inno Setup 6\ISCC.exe"
    )
    foreach ($p in $searchPaths) {
        if ($p -and (Test-Path $p)) {
            $iscc = $p
            break
        }
    }
}

if (-not $iscc) {
    Write-Host "Inno Setup not found in standard paths. Attempting Chocolatey install..." -ForegroundColor Yellow
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install innosetup --no-progress -y
        $iscc = "$env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe"
        if (-not (Test-Path $iscc)) {
            $iscc = "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
        }
    }
}

if (-not $iscc -or -not (Test-Path $iscc)) {
    Write-Error "Inno Setup 6 (ISCC.exe) not found! Please install it from https://jrsoftware.org/isdl.php"
}
Write-Host "Using Inno Setup: $iscc" -ForegroundColor Green

# Create output dir
$installerOutputDir = "build\windows-installer"
if (-not (Test-Path $installerOutputDir)) {
    New-Item -ItemType Directory -Force -Path $installerOutputDir | Out-Null
}

Write-Host "Compiling installer..." -ForegroundColor Yellow
& $iscc "/DMyAppVersion=$Version" "windows\packaging\rupayan_sitesync_installer.iss"

$setupExe = "$installerOutputDir\RupayanSetup.exe"
if (-not (Test-Path $setupExe)) {
    Write-Error "Installer compilation finished but $setupExe was not found!"
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "  Installer generated at: $(Resolve-Path $setupExe)" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

if ($OpenFolder) {
    Invoke-Item $installerOutputDir
}
