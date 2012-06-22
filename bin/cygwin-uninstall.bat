@echo off
rem
rem Uninstall Cygwin.
rem See http://cygwin.com/faq/faq-nochunks.html#faq.setup.uninstall-all
rem

setlocal

set _ROOTDIR=C:\cygwin
set _PREFIX=CYGWIN-UNINSTALL:

goto :main

:check_rootdir
    echo %_PREFIX% Checking if %_ROOTDIR% is valid
    if exist "%_ROOTDIR%" goto :endif_rootdir
        echo %_PREFIX% ERROR: ROOTDIR "%_ROOTDIR%" does not exist.
        exit /b 1
    :endif_rootdir
    if exist "%_ROOTDIR%\Cygwin.ico" goto :endif_cygwin_ico
        echo %_PREFIX% ERROR: ROOTDIR "%_ROOTDIR%" does not appear to be a Cygwin directory.
        exit /b 1
    :endif_cygwin_ico
goto :eof

:check_admin
    rem Check for ADMIN privileges
    rem https://sites.google.com/site/eneerge/home/BatchGotAdmin

    echo %_PREFIX% Checking for Administrator privileges
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
    if "%ERRORLEVEL%" EQU "0" goto :endif_check_admin
        echo %_PREFIX% ERROR: You do not have Administrator privileges
        echo %_PREFIX% Rerun from a "Run as Administrator" command prompt
        exit /b 1
    :endif_check_admin
goto :eof

:uninstall_lsa
    echo %_PREFIX% Checking if cyglsa is hooked into OS
    reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages" | findstr cyglsa > NUL:
    if %ERRORLEVEL% NEQ 0 exit /b 0

    echo %_PREFIX% Checking for sane Authentication Packages value
    for /f "usebackq tokens=4-9" %%f in (`reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages"`) do set _AP_VALUE=%%f
    set _AP_VALUEQ=%_AP_VALUE:\0=?%
    for /f "usebackq delims=? tokens=1,2,3" %%f in ('%_AP_VALUEQ%') do (
        set _AP_VALUE_0=%%f
        set _AP_VALUE_1=%%g
        set _AP_VALUE_2=%%h
    )
    if not "%_AP_VALUE_0%" == "msv1_0" goto :lsa_bad
    echo %_AP_VALUE_1% | findstr cyglsa > NUL:
    if %ERRORLEVEL% NEQ 0 goto :lsa_bad
    if not "%_AP_VALUE_2%" == "" goto :lsa_bad

    echo %_PREFIX% Unhooking cyglsa
    reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages" /t REG_MULTI_SZ /f /d msv1_0
    echo %_PREFIX% Please reboot and rerun this script
    exit /b 1

    :lsa_bad
    echo %_PREFIX% ERROR: Don't know how to handle Authentication Packages value of %_AP_VALUE%
    exit /b 1
goto :eof

:stop_services
    echo %_PREFIX% Stopping Cygwin services
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do %_ROOTDIR%\bin\cygrunsrv --stop %%s
goto :eof

:remove_services
    echo %_PREFIX% Removing Cygwin services
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do %_ROOTDIR%\bin\cygrunsrv --remove %%s
goto :eof

:clean_registry
    echo %_PREFIX% Removing Software\Cygwin from registry
    reg delete HKLM\Software\Cygwin /va /f > NUL: 2>&1
    reg delete HKLM\Software\Wow6432Node\Cygwin /va /f > NUL: 2>&1
    reg delete HKCU\Software\Cygwin /va /f > NUL: 2>&1
goto :eof

:remove_cygwin_dir
    echo %_PREFIX% Removing %_ROOTDIR%
    rd /s /q %_ROOTDIR%
goto :eof

:remove_local_users
    echo %_PREFIX% Remove sshd and cyg_server local users!
goto :eof

:main
    call :check_rootdir ||exit /b 1
    call :check_admin ||exit /b 1
    call :uninstall_lsa ||exit /b 1
    call :stop_services ||exit /b 1
    call :remove_services ||exit /b 1
    call :clean_registry ||exit /b 1
    rem call :remove_shortcuts ||exit /b 1
    call :remove_cygwin_dir ||exit /b 1
    call :remove_local_users ||exit /b 1
