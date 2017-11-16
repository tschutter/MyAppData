@echo off
rem
rem Uninstall Cygwin.
rem See http://cygwin.com/faq/faq-nochunks.html#faq.setup.uninstall-all
rem
rem This would be much easier to implement as a shell script, but
rem sometimes the whole point of uninstalling Cygwin is that it is in a
rem non-working state.
rem
rem Copyright (c) 2012-2013 Tom Schutter
rem All rights reserved.
rem
rem Redistribution and use in source and binary forms, with or without
rem modification, are permitted provided that the following conditions
rem are met:
rem
rem    - Redistributions of source code must retain the above copyright
rem      notice, this list of conditions and the following disclaimer.
rem    - Redistributions in binary form must reproduce the above
rem      copyright notice, this list of conditions and the following
rem      disclaimer in the documentation and/or other materials provided
rem      with the distribution.
rem
rem THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
rem "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
rem LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
rem FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
rem COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
rem INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
rem BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
rem LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
rem CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
rem LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
rem ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
rem POSSIBILITY OF SUCH DAMAGE.
rem

setlocal

rem Global constants.
set _PREFIX=CYGWIN_UNINSTALL:

goto :main

:load_config
    set _CONFFILE=%~dp0\cygwin_setup_config.bat
    if exist "%_CONFFILE%" goto :endif_check_conffile
        echo %_PREFIX% ERROR: Configuration file "%_CONFFILE%" not found.
        exit /b 1
    :endif_check_conffile
    set _ROOTDIR=
    call "%_CONFFILE%"
    if "%_ROOTDIR%" == "" (
        echo %_PREFIX% ERROR: _ROOTDIR not defined in "%_CONFFILE%"
        exit /b 1
    )
exit /b 0


:check_rootdir
    rem Return 1 if _ROOTDIR is not a Cygwin root directory, 0 otherwise.
    echo %_PREFIX% Checking if %_ROOTDIR% is valid...
    if exist "%_ROOTDIR%" goto :endif_rootdir
        echo %_PREFIX% ERROR: ROOTDIR "%_ROOTDIR%" does not exist.
        exit /b 1
    :endif_rootdir
    if exist "%_ROOTDIR%\Cygwin.ico" goto :endif_cygwin_ico
        echo %_PREFIX% ERROR: ROOTDIR "%_ROOTDIR%" does not appear to be a Cygwin directory.
        exit /b 1
    :endif_cygwin_ico
exit /b 0


:check_admin
    rem Check for ADMIN privileges.  Return 1 if script is not being
    rem run as Administrator, 0 if it is.
    rem https://sites.google.com/site/eneerge/home/BatchGotAdmin

    echo %_PREFIX% Checking for Administrator privileges...
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
    if "%ERRORLEVEL%" EQU "0" goto :endif_check_admin
        echo %_PREFIX% ERROR: You do not have Administrator privileges
        echo %_PREFIX% Rerun from a "Run as Administrator" command prompt
        exit /b 1
    :endif_check_admin
exit /b 0


:uninstall_lsa
    rem Return 1 if problems encountered when uninstalling cyglsa, 0 otherwise.
    echo %_PREFIX% Checking if cyglsa is hooked into OS...
    reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v "Authentication Packages" | findstr cyglsa > NUL:
    if %ERRORLEVEL% NEQ 0 exit /b 0

    echo %_PREFIX% Checking for sane Authentication Packages value...
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


:stop_services
    echo %_PREFIX% Stopping Cygwin services
    for /f "usebackq" %%s in (`%_ROOTDIR%\bin\cygrunsrv.exe --list`) do %_ROOTDIR%\bin\cygrunsrv --stop %%s
goto :eof


:check_for_cygwin_proc
    rem Check for any Cygwin processes.  Return 1 if uninstall should be aborted, 0 otherwise.
    echo %_PREFIX% Checking for running Cygwin processes...
    if not exist "%_ROOTDIR%\bin\ps.exe" exit /b 0
    set _TEMPFILE=%TEMP%\cygwin_setup.txt
    :retry
        "%_ROOTDIR%\bin\ps.exe" -l | findstr /v /c:"/usr/bin/ps" > %_TEMPFILE%
        findstr /v /r /c:"PID.*COMMAND" %_TEMPFILE% | findstr /r /c:"^..*" > NUL:
        if ERRORLEVEL 1 goto :ignore
        echo %_PREFIX% Found running Cygwin processes
        type %_TEMPFILE%
        del %_TEMPFILE%
        :ask_abort_retry_ignore
            set /p _ANSWER=Abort, Retry, or Ignore?
            set _ANSWER=%_ANSWER:~0,1%
            if "%_ANSWER%" == "a" exit /b 1
            if "%_ANSWER%" == "A" exit /b 1
            if "%_ANSWER%" == "r" goto :retry
            if "%_ANSWER%" == "R" goto :retry
            if "%_ANSWER%" == "i" goto :ignore
            if "%_ANSWER%" == "I" goto :ignore
        goto :ask_abort_retry_ignore
    :ignore
exit /b 0


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


:remove_shortcuts
    echo %_PREFIX% Remove Cygwin shell shortcuts from Desktop and Start menu!
goto :eof


:is_cygwin_user
    rem Return 1 if the %1 user appears to have been created by Cygwin, 0 otherwise.
    set _HOMEDIR=
    for /f "usebackq tokens=3*" %%d in (`net user %1 2^>NUL ^| findstr /c:"Home\ directory" 2^>NUL`) do set _HOMEDIR=%%d
    if "%_HOMEDIR%" == "" exit /b 0
    echo %_HOMEDIR% | findstr /lib "%_ROOTDIR%" >NUL && exit /b 1
exit /b 0


:remove_local_user
    :remove_local_user_ask
        set /p _ANSWER=%_PREFIX% Remove local Cygwin user "%1" (y/n)?
        if "%_ANSWER%" == "n" goto :eof
        if "%_ANSWER%" == "N" goto :eof
        if "%_ANSWER%" == "y" goto :remove_local_user_ask_done
        if "%_ANSWER%" == "Y" goto :remove_local_user_ask_done
        goto :remove_local_user_ask
    :remove_local_user_ask_done
    echo %_PREFIX% Removing local user "%1"
    net user %1 /remove
goto :eof


:remove_local_cygwin_users
    echo %_PREFIX% Searching for users created by Cygwin...
    for /f "usebackq tokens=*" %%l in (`net user`) do (
        rem %%l is a line of output from "net user", split it into words.
        for %%u in (%%l) do (
            rem Note that many of these "users" are just cruft from the "net user" command.
            call :is_cygwin_user %%u || call :remove_local_user %%u
        )
    )
goto :eof


:main
    call :load_config ||exit /b 1
    call :check_rootdir ||exit /b 1
    call :check_admin ||exit /b 1
    call :remove_local_cygwin_users
    call :uninstall_lsa ||exit /b 1
    call :stop_services
    call :check_for_cygwin_proc ||exit /b 1
    call :remove_services
    call :clean_registry
    call :remove_cygwin_dir
    call :remove_shortcuts
    call :remove_local_users
