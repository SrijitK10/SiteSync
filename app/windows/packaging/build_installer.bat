@echo off
setlocal enabledelayedexpansion
title Rupayan SiteSync - Windows Installer Builder

echo ========================================================
echo   Rupayan SiteSync - Local Windows Installer Builder
echo ========================================================
echo.

cd /d "%~dp0\..\.."

where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter SDK not found in PATH!
    echo Please install Flutter and ensure it is added to your PATH.
    pause
    exit /b 1
)

echo [1/4] Enabling Windows desktop support...
call flutter config --enable-windows-desktop
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to enable Windows desktop in Flutter.
    pause
    exit /b 1
)

echo.
echo [2/4] Installing dependencies...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 'flutter pub get' failed.
    pause
    exit /b 1
)

echo.
echo [3/4] Building Windows Release binary...
if not exist "build\windows\x64" mkdir "build\windows\x64"
echo CMAKE_POLICY_VERSION_MINIMUM:STRING=3.5> "build\windows\x64\CMakeCache.txt"
call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 'flutter build windows --release' failed.
    pause
    exit /b 1
)

if not exist "build\windows\x64\runner\Release\rupayan.exe" (
    echo [ERROR] Release binary build\windows\x64\runner\Release\rupayan.exe not found!
    pause
    exit /b 1
)

echo.
echo [4/4] Locating Inno Setup Compiler (ISCC)...
set "ISCC_PATH="
where iscc.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "tokens=*" %%i in ('where iscc.exe') do (
        set "ISCC_PATH=%%i"
        goto :FoundISCC
    )
)

if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" (
    set "ISCC_PATH=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
    goto :FoundISCC
)

if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" (
    set "ISCC_PATH=%ProgramFiles%\Inno Setup 6\ISCC.exe"
    goto :FoundISCC
)

if exist "%LocalAppData%\Programs\Inno Setup 6\ISCC.exe" (
    set "ISCC_PATH=%LocalAppData%\Programs\Inno Setup 6\ISCC.exe"
    goto :FoundISCC
)

echo [ERROR] Inno Setup 6 (ISCC.exe) was not found!
echo Please download and install Inno Setup 6 from:
echo https://jrsoftware.org/isdl.php
pause
exit /b 1

:FoundISCC
echo Found Inno Setup Compiler at: "%ISCC_PATH%"
if not exist "build\windows-installer" mkdir "build\windows-installer"

echo Compiling installer with Inno Setup...
"%ISCC_PATH%" "windows\packaging\rupayan_sitesync_installer.iss"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Inno Setup compilation failed!
    pause
    exit /b 1
)

echo.
echo ========================================================
echo   BUILD SUCCESSFUL!
echo   Installer created at:
echo   %CD%\build\windows-installer\RupayanSetup.exe
echo ========================================================
echo.
pause
