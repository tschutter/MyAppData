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
    if not exist "%_ROOTDIR%" (
        echo %_PREFIX% ERROR: ROOTDIR "%_ROOTDIR%" does not exist.
        exit
    )
    if not exist "%_ROOTDIR%\Cygwin.ico" (
        echo %_PREFIX% ERROR: ROOTDIR "%_ROOTDIR%" does not appear to be a Cygwin directory.
        exit
    )
goto :eof

:check_admin
    rem Check for ADMIN privileges
    rem https://sites.google.com/site/eneerge/home/BatchGotAdmin

    echo %_PREFIX% Checking for Administrator privileges
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
    if "%ERRORLEVEL%" NEQ "0" (
        echo %_PREFIX% ERROR: You do not have Administrator privileges
        echo %_PREFIX% Rerun from a "Run as Administrator" command prompt
        exit
    )
goto :eof

:stop_services
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do %_ROOTDIR%\bin\cygrunsrv --stop %%s
goto :eof

:remove_services
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do %_ROOTDIR%\bin\cygrunsrv --remove %%s
goto :eof

:uninstall_lsa
    reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages" | findstr cyglsa > NUL:
    if %ERRORLEVEL% NEQ 0 goto :eof

    rem Check for sane Authentication Packages value.
    for /f "usebackq tokens=4-9" %%f in (`reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages"`) do set _AP_VALUE=%%f
    set _AP_VALUE=%_AP_VALUE:\0=?%
    for /f "usebackq delims=? tokens=1,2,3" %f in ('%_AP_VALUE%') do (
        set _AP_VALUE_0=%f
        set _AP_VALUE_1=%g
        set _AP_VALUE_2=%h
    )
    if not "%_AP_VALUE_0" == "msv1_0" goto :lsa_bad
    echo %_AP_VALUE_1% | findstr cyglsa > NUL:
    if %ERRORLEVEL% NEQ 0 goto :lsa_bad
    if not "%_AP_VALUE_2" == "" goto :lsa_bad

    echo %_PREFIX% Uninstalling lsa
    echo reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages" /t REG_MULTI_SZ /f /d msv1_0
    echo %_PREFIX% Please reboot and rerun this script
    exit

    :lsa_bad
    echo %_PREFIX% ERROR: Don't know how to handle LSA value of %_AP_VALUE%
    exit
goto :eof

:remove_cygwin_dir
    rd /s /q %_ROOTDIR%
goto :eof

:clean_registry
    echo %_PREFIX% Removing Software\Cygwin from registry
    reg delete HKLM\Software\Cygwin /va /f
    reg delete HKLM\Software\Wow6432Node\Cygwin /va /f
    reg delete HKCU\Software\Cygwin /va /f
goto :eof

:remove_local_users
    echo Remove sshd and cyg_server local users!
goto :eof

:main
    call :check_rootdir
    call :check_admin
    call :uninstall_lsa
    call :stop_services
    call :remove_services
    rem call :remove_shortcuts
    call :remove_cygwin_dir
    call :clean_registry
    call :remove_local_users
