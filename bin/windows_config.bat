@echo off

setlocal

rem Check if Python3 is installed.
for /f %%i in ("python3.exe") do set _FOUND=%%~$PATH:i
if not "%_FOUND%" == "" goto :endif
    echo ERROR: Python3 not installed.  See http://python.org/download/
    goto :eof
:endif

python3.exe "%~dp0/windows_config.py" %*
