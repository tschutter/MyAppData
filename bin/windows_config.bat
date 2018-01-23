@echo off

setlocal

rem Locate python.exe.
for /f %%i in ("python.exe") do set _FOUND=%%~$PATH:i
if not "%_FOUND%" == "" goto :endif
    echo ERROR: python.exe not found.
    goto :eof
:endif

rem Determine if python.exe is Python3.
"%_FOUND%" --version | findstr /B /L /C:"Python 3" >NUL 2>&1
if not ERRORLEVEL 1 goto :endif2
    echo ERROR: python.exe is not Python3.
    goto :eof
:endif2

rem python.exe "%~dp0windows_config.py" %*
