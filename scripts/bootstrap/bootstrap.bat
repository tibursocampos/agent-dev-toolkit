@echo off
REM Windows entrypoint for toolkit Release bootstrap (HTTPS + SHA256 → extract → toolkit.ps1).
REM Forwards to bootstrap.ps1 — no gh CLI, Node, or compiled .exe bootstrap artifact required.
REM Fixed Release assets: agent-dev-toolkit.zip + agent-dev-toolkit.zip.sha256 (override via args/env).
REM Default after extract: interactive scripts/toolkit.ps1. Optional -DirectSync → sync-agent.ps1.
REM A browser download is marked and RemoteSigned refuses bootstrap.ps1. This .bat clears that mark
REM and starts PowerShell with -ExecutionPolicy Bypass. A failed double-click keeps the window open.
setlocal EnableExtensions
set "SCRIPT_DIR=%~dp0"
set "BOOTSTRAP_PS1=%SCRIPT_DIR%bootstrap.ps1"
set "BOOTSTRAP_PS1_URL=https://github.com/tibursocampos/agent-dev-toolkit/releases/latest/download/bootstrap.ps1"

if exist "%BOOTSTRAP_PS1%" goto unblock_and_invoke
where curl.exe >nul 2>&1
if errorlevel 1 goto no_bootstrap_ps1
echo bootstrap.bat: bootstrap.ps1 missing; downloading from Release (HTTPS)...
curl.exe -fsSL --proto "=https" -o "%BOOTSTRAP_PS1%" "%BOOTSTRAP_PS1_URL%"
if errorlevel 1 goto download_failed
if not exist "%BOOTSTRAP_PS1%" goto download_failed

:unblock_and_invoke
call :unblock_downloaded_script
where pwsh >nul 2>&1
if errorlevel 1 goto try_windows_powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP_PS1%" %*
goto finish_invoke

:try_windows_powershell
where powershell >nul 2>&1
if errorlevel 1 goto no_powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP_PS1%" %*

:finish_invoke
if errorlevel 1 goto invoke_failed
exit /b 0

:unblock_downloaded_script
where powershell >nul 2>&1
if errorlevel 1 exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -LiteralPath $env:BOOTSTRAP_PS1"
exit /b 0

:invoke_failed
echo bootstrap.bat: bootstrap.ps1 failed with exit code %ERRORLEVEL%. 1>&2
call :pause_when_double_clicked
exit /b 1

:no_powershell
echo bootstrap.bat: PowerShell not found. Install pwsh 7+ or Windows PowerShell 5.1+. 1>&2
call :pause_when_double_clicked
exit /b 1

:no_bootstrap_ps1
echo bootstrap.bat: bootstrap.ps1 missing beside this .bat and curl.exe not found to download it. 1>&2
call :pause_when_double_clicked
exit /b 1

:download_failed
echo bootstrap.bat: failed to download bootstrap.ps1 from Release (HTTPS). 1>&2
call :pause_when_double_clicked
exit /b 1

:pause_when_double_clicked
echo %CMDCMDLINE% | find /I "/c" >nul
if not errorlevel 1 pause
exit /b 0
