@echo off
rem
rem Install or update Cygwin.
rem

setlocal

set _ROOTDIR=C:\cygwin
set _PREFIX=CYGWIN-UNINSTALL:

goto :main

:stop_services
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do %_ROOTDIR%\bin\cygrunsrv --stop %%s
goto :eof

:remove_services
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do %_ROOTDIR%\bin\cygrunsrv --remove %%s
goto :eof

:uninstall_lsa
    reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages" | findstr cyglsa > NUL:
    if %ERRORLEVEL% NEQ 0 goto :eof
    echo %_PREFIX% Uninstalling lsa
    echo %_PREFIX% WARNING: need administrator priv here
    rem reg XXX HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages"
    echo %_PREFIX% Please reboot and rerun this script
    exit
goto :eof

:main
    call :uninstall_lsa
    call :stop_services
    call :remove_services
    rem call :remove_local_users
    rem call :remove_cygwin_dir
    rem review FAQ

endlocal
