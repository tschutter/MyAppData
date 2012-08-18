@echo off

setlocal

rem Check if Python is installed.
for /f %%i in ("python.exe") do set _FOUND=%%~$PATH:i
if not "%_FOUND%" == "" goto :endif
    echo ERROR: Python not installed.  See http://python.org/download/
    goto :eof
:endif

python.exe "%~dp0/windows_config.py" %*
