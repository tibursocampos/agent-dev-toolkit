@echo off
REM Windows entrypoint for toolkit Release bootstrap (HTTPS + SHA256 → sync-agent).
REM Forwards to bootstrap.ps1 — no gh CLI, Node, or compiled .exe bootstrap artifact required.
REM Zip/checksum asset names: pass through args or env TOOLKIT_RELEASE_* (confirm vs CI).
REM After -Extract: sync handoff via scripts/sync-agent.ps1 (-SkipSync / -SyncWhatIf supported).
setlocal EnableExtensions
set "SCRIPT_DIR=%~dp0"

where pwsh >nul 2>&1
if errorlevel 1 goto try_windows_powershell
pwsh -NoProfile -File "%SCRIPT_DIR%bootstrap.ps1" %*
exit /b %ERRORLEVEL%

:try_windows_powershell
where powershell >nul 2>&1
if errorlevel 1 goto no_powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%bootstrap.ps1" %*
exit /b %ERRORLEVEL%

:no_powershell
echo bootstrap.bat: PowerShell not found. Install pwsh 7+ or Windows PowerShell 5.1+. 1>&2
exit /b 1
